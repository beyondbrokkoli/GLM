import argparse
import math
import random
from typing import Set, Dict, Optional, List, Tuple, Union

MOVE_CHAINS = False
MAX_TRIPS = 64
MAX_ROOTS = 8
I64_MOD = 1 << 64
NULL_ROOT = -1  # Compile-time sentinel for freed / nil memory


def wrap64(x):
    """Lua 5.4 integers are i64 with wrapping +,-,*."""
    return (x + (1 << 63)) % I64_MOD - (1 << 63)


def is_int(x):
    return type(x) is int


def is_flt(x):
    return type(x) is float


def is_bool(x):
    return type(x) is bool


class UnsafeProgram(Exception):
    """The program under construction left the verifiable subset."""


def flt(x):
    if not math.isfinite(x):
        raise UnsafeProgram("non-finite float")
    return x


class AliasSet:
    """Tracks abstract memory sites and NULL_ROOT taint."""
    __slots__ = ("sites",)

    def __init__(self, sites: Optional[Set[int]] = None):
        self.sites: Set[int] = set(sites) if sites is not None else set()

    def union(self, other: 'AliasSet') -> 'AliasSet':
        return AliasSet(self.sites | other.sites)

    def overwrite_with_null(self):
        self.sites = {NULL_ROOT}

    def has_null(self) -> bool:
        return NULL_ROOT in self.sites

    def copy(self) -> 'AliasSet':
        return AliasSet(self.sites.copy())

    def __repr__(self):
        return f"AliasSet({sorted(list(self.sites))})"


class TableHeap:
    """Models physical table storage indexed by abstract site_id."""
    __slots__ = ("site_id", "cells", "span", "alive", "elem", "deep_free", "children")

    def __init__(self, site_id: int, elem: Union[str, Tuple] = "int", deep_free: bool = False):
        self.site_id = site_id
        self.cells = {}
        self.span = 0
        self.alive = True
        self.elem = elem
        self.deep_free = deep_free
        self.children: Set[int] = set()

    def grow(self, want):
        if want > self.span:
            self.span = max(want, self.span * 2, 8)

    def copy(self) -> 'TableHeap':
        th = TableHeap(self.site_id, self.elem, self.deep_free)
        th.cells = dict(self.cells)
        th.span = self.span
        th.alive = self.alive
        th.children = set(self.children)
        return th


NULL_SENTINEL = object()


class ScopeEnvironment:
    """Lattice-aware scope environment mirroring shape.rs."""
    def __init__(self):
        self.scopes: List[Dict[str, object]] = [{}]
        self.alias_scopes: List[Dict[str, AliasSet]] = [{}]
        self.heap: Dict[int, TableHeap] = {}
        self._site_counter = 0

    def push(self):
        self.scopes.append({})
        self.alias_scopes.append({})

    def pop(self):
        self.scopes.pop()
        self.alias_scopes.pop()

    def fresh_site(self) -> int:
        self._site_counter += 1
        return self._site_counter

    def allocate_table(self, name: Optional[str], elem="int", local=True, deep_free=False) -> TableHeap:
        sid = self.fresh_site()
        heap_obj = TableHeap(sid, elem, deep_free)
        self.heap[sid] = heap_obj
        if name:
            aset = AliasSet({sid})
            if local:
                self.scopes[-1][name] = heap_obj
                self.alias_scopes[-1][name] = aset
            else:
                self.assign(name, heap_obj)
                self.set_alias(name, aset)
        return heap_obj

    def get_var_binding(self, name: str):
        for sc in reversed(self.scopes):
            if name in sc:
                return sc[name]
        raise UnsafeProgram(f"undeclared variable {name}")

    def get_alias_set(self, name: str) -> Optional[AliasSet]:
        for sc in reversed(self.alias_scopes):
            if name in sc:
                return sc[name]
        return None

    def declare(self, name: str, val: object, aset: Optional[AliasSet] = None):
        self.scopes[-1][name] = val
        self.alias_scopes[-1][name] = aset.copy() if aset is not None else AliasSet()

    def assign(self, name: str, val: object):
        for sc in reversed(self.scopes):
            if name in sc:
                sc[name] = val
                return
        raise UnsafeProgram(f"assignment to undeclared {name}")

    def set_alias(self, name: str, aset: AliasSet):
        for sc in reversed(self.alias_scopes):
            if name in sc:
                sc[name] = aset.copy()
                return
        raise UnsafeProgram(f"alias update on undeclared {name}")

    def can_safely_read(self, name: str) -> bool:
        aset = self.get_alias_set(name)
        if aset is None or aset.has_null():
            return False
        val = self.get_var_binding(name)
        if val is NULL_SENTINEL:
            return False
        if isinstance(val, TableHeap) and not val.alive:
            return False
        return True

    def _physical_free(self, sid: int):
        """Recursively frees memory respecting deep_free inline structures."""
        if sid in self.heap and self.heap[sid].alive:
            self.heap[sid].alive = False
            if self.heap[sid].deep_free:
                for child_sid in self.heap[sid].children:
                    self._physical_free(child_sid)

    def assign_nil(self, name: str):
        """Drops name reference; tests physical free via sole-check."""
        val = self.get_var_binding(name)
        aset = self.get_alias_set(name)

        if val is NULL_SENTINEL or (aset and aset.sites == {NULL_ROOT}):
            return

        if not isinstance(val, TableHeap) and (not aset or not aset.sites):
            raise UnsafeProgram("'t = nil' on non-table variable")

        prior_sites = aset.sites.copy() if aset else set()
        prior_sites.discard(NULL_ROOT)

        # Poison the local pointer
        self.assign(name, NULL_SENTINEL)
        if aset:
            aset.overwrite_with_null()
        else:
            self.set_alias(name, AliasSet({NULL_ROOT}))

        # Sole vs. Shared Check: Scan whole scope stack
        for sid in prior_sites:
            aliased = False
            for sc_alias in self.alias_scopes:
                for var, other_aset in sc_alias.items():
                    if sid in other_aset.sites:
                        aliased = True
                        break
                if aliased:
                    break
            if not aliased:
                self._physical_free(sid)

    def can_safely_drop_in_loop(self, name: str, loop_reads: Set[str]) -> bool:
        is_inner = False
        for sc in reversed(self.scopes):
            if name in sc:
                if sc is self.scopes[-1]:
                    is_inner = True
                break
        if is_inner:
            return True
        return name not in loop_reads

    def visible(self, pred):
        out = []
        seen = set()
        for sc in reversed(self.scopes):
            for k, v in sc.items():
                if k not in seen:
                    seen.add(k)
                    if pred(v):
                        out.append(k)
        return out

    def snapshot(self) -> 'ScopeEnvironment':
        clone = ScopeEnvironment()
        clone._site_counter = self._site_counter
        clone.heap = {sid: th.copy() for sid, th in self.heap.items()}
        clone.scopes = []
        for sc in self.scopes:
            new_sc = {}
            for k, v in sc.items():
                if isinstance(v, TableHeap):
                    new_sc[k] = clone.heap[v.site_id]
                else:
                    new_sc[k] = v
            clone.scopes.append(new_sc)
        clone.alias_scopes = [{k: aset.copy() for k, aset in asc.items()} for asc in self.alias_scopes]
        return clone


# AST Evaluator

def ev(n, m: ScopeEnvironment):
    t = n[0]
    if t == "lit":
        return n[1]
    if t == "var":
        name = n[1]
        if not m.can_safely_read(name):
            raise UnsafeProgram(f"read of NULL_ROOT-tainted alias or dropped variable {name}")
        v = m.get_var_binding(name)
        if v is NULL_SENTINEL:
            raise UnsafeProgram(f"use of freed name {name}")
        return v
    if t == "new":
        return m.allocate_table(None, "int")
    if t == "newf":
        return m.allocate_table(None, "float")
    if t == "table_lit":
        elem_type = n[1]
        elements = [ev(e, m) for e in n[2]]
        heap_obj = m.allocate_table(None, elem=elem_type, deep_free=True)
        for idx, val in enumerate(elements):
            # LUA 1-BASED INDEXING FIX
            heap_obj.grow(idx + 2)
            heap_obj.cells[idx + 1] = val 
            if isinstance(val, TableHeap):
                heap_obj.children.add(val.site_id)
        return heap_obj
    if t == "read":
        name = n[1]
        if not m.can_safely_read(name):
            raise UnsafeProgram(f"table read on tainted name {name}")
        root = m.get_var_binding(name)
        if not isinstance(root, TableHeap) or not root.alive:
            raise UnsafeProgram(f"read of dead or non-table {name}")
        i = ev(n[2], m)
        if not is_int(i) or i < 0:
            raise UnsafeProgram("negative table index")
        if i >= root.span:
            raise UnsafeProgram("read outside observable span")
        return root.cells.get(i)
    if t == "multi_read":
        name = n[1]
        if not m.can_safely_read(name):
            raise UnsafeProgram(f"multi_read on poisoned name {name}")
        root = m.get_var_binding(name)
        for idx_node in n[2]:
            if not isinstance(root, TableHeap) or not root.alive:
                raise UnsafeProgram("multi_read on dead/scalar")
            i = ev(idx_node, m)
            if not is_int(i) or i < 0:
                raise UnsafeProgram("negative table index")
            if i >= root.span:
                raise UnsafeProgram("read outside observable span")
            if i not in root.cells and idx_node is not n[2][-1]:
                raise UnsafeProgram("intermediate multi_read hit nil")
            root = root.cells.get(i)
        return root
    if t == "un":
        x = ev(n[2], m)
        if n[1] == "not":
            if not is_bool(x):
                raise UnsafeProgram("'not' on non-bool")
            return not x
        if is_int(x):
            return wrap64(-x)
        if is_flt(x):
            return flt(-x)
        raise UnsafeProgram("negation on non-numeric")
    if t == "bin":
        op = n[1]
        if op in ("and", "or"):
            a = ev(n[2], m)
            if not is_bool(a):
                raise UnsafeProgram("logic op on non-bool")
            if (op == "and" and not a) or (op == "or" and a):
                return a
            b = ev(n[3], m)
            if not is_bool(b):
                raise UnsafeProgram("logic op on non-bool")
            return b
        a = ev(n[2], m)
        b = ev(n[3], m)

        # Abort comparing Lua nils (our abstract machine's None)
        if a is None or b is None:
            raise UnsafeProgram("comparison on nil")

        if op in ("==", "~="):
            if type(a) is not type(b):
                raise UnsafeProgram("mixed-type equality")
            eq = (a.site_id == b.site_id) if isinstance(a, TableHeap) else (a == b)
            return eq if op == "==" else not eq
        if op in ("<", "<=", ">", ">="):
            if not ((is_int(a) and is_int(b)) or (is_flt(a) and is_flt(b))):
                raise UnsafeProgram("ordered compare on mixed/nil types")
            if op == "<": return a < b
            if op == "<=": return a <= b
            if op == ">": return a > b
            return a >= b
        if is_int(a) and is_int(b):
            if op == "+": return wrap64(a + b)
            if op == "-": return wrap64(a - b)
            if op == "*": return wrap64(a * b)
            if op == "//":
                if b == 0: raise UnsafeProgram("integer div by zero")
                return wrap64(a // b)
            if op == "%":
                if b == 0: raise UnsafeProgram("integer mod by zero")
                return wrap64(a % b)
        if is_flt(a) and is_flt(b):
            if op == "+": return flt(a + b)
            if op == "-": return flt(a - b)
            if op == "*": return flt(a * b)
            if op == "/": return flt(a / b)
            if op == "//": return flt(a // b)
            if op == "%": return flt(a % b)
        raise UnsafeProgram("arithmetic type failure")
    raise UnsafeProgram(f"unknown node {t}")


def render(n):
    t = n[0]
    if t == "lit":
        v = n[1]
        if is_bool(v):
            return "true" if v else "false"
        if isinstance(v, str):
            return f'"{v}"'
        return repr(v)
    if t == "var":
        return n[1]
    if t in ("new", "newf"):
        return "{}"
    if t == "table_lit":
        return "{" + ", ".join(render(e) for e in n[2]) + "}"
    if t == "read":
        return f"{n[1]}[{render(n[2])}]"
    if t == "multi_read":
        res = n[1]
        for idx in n[2]:
            res += f"[{render(idx)}]"
        return res
    if t == "un":
        return f"(-{render(n[2])})" if n[1] == "neg" else f"(not {render(n[2])})"
    return f"({render(n[2])} {n[1]} {render(n[3])})"


def render_stmt(s):
    t = s[0]
    if t in ("local", "assign"):
        kw = "local " if t == "local" else ""
        return f"{kw}{s[1]} = {render(s[2])}"
    if t == "nilfree":
        return f"{s[1]} = nil"
    if t == "store":
        return f"{s[1]}[{render(s[2])}] = {render(s[3])}"
    if t == "multi_store":
        res = s[1]
        for idx in s[2]:
            res += f"[{render(idx)}]"
        return f"{res} = {render(s[3])}"
    if t == "print":
        return "print(" + ", ".join(render(a) for a in s[1]) + ")"
    raise UnsafeProgram(f"statement {t} cannot render inline")


def ex(s, m: ScopeEnvironment):
    t = s[0]
    if t == "local":
        val = ev(s[2], m)
        aset = AliasSet()
        if isinstance(val, TableHeap):
            aset = AliasSet({val.site_id})
        elif s[2][0] == "var":
            src_alias = m.get_alias_set(s[2][1])
            if src_alias:
                aset = src_alias.copy()
        m.declare(s[1], val, aset)
    elif t == "assign":
        val = ev(s[2], m)
        aset = AliasSet()
        if isinstance(val, TableHeap):
            aset = AliasSet({val.site_id})
        elif s[2][0] == "var":
            src_alias = m.get_alias_set(s[2][1])
            if src_alias:
                aset = src_alias.copy()
        m.assign(s[1], val)
        m.set_alias(s[1], aset)
    elif t == "nilfree":
        m.assign_nil(s[1])
    elif t == "store":
        name = s[1]
        if not m.can_safely_read(name):
            raise UnsafeProgram(f"store through poisoned or nil-tainted table {name}")
        root = m.get_var_binding(name)
        if not isinstance(root, TableHeap) or not root.alive:
            raise UnsafeProgram("store into a dead table")
        i = ev(s[2], m)
        if not is_int(i) or i < 0 or i > 4096:
            raise UnsafeProgram("store index out of bounds")
        v = ev(s[3], m)
        root.grow(i + 1)
        root.cells[i] = v
        if isinstance(v, TableHeap):
            root.children.add(v.site_id)
            if s[3][0] == "var":
                root.deep_free = False
    elif t == "multi_store":
        name = s[1]
        if not m.can_safely_read(name):
            raise UnsafeProgram("multi_store through poisoned table")
        root = m.get_var_binding(name)
        indices = [ev(idx, m) for idx in s[2]]
        val = ev(s[3], m)

        for i in indices[:-1]:
            if not isinstance(root, TableHeap) or not root.alive:
                raise UnsafeProgram("Mid-traverse error on dead/scalar")
            if not is_int(i) or i < 0:
                raise UnsafeProgram("negative index in multi_store")
            if i not in root.cells:
                raise UnsafeProgram("Mid-traverse error: hit unwritten nil")
            root = root.cells.get(i)

        if not isinstance(root, TableHeap) or not root.alive:
            raise UnsafeProgram("Mid-traverse error on dead/scalar final")
        idx = indices[-1]
        if not is_int(idx) or idx < 0:
            raise UnsafeProgram("negative index")

        root.grow(idx + 1)
        root.cells[idx] = val
        if isinstance(val, TableHeap):
            root.children.add(val.site_id)
            if s[3][0] == "var":
                root.deep_free = False
    elif t == "while":
        for name, bnode in s[3]:
            if not m.can_safely_read(name):
                raise UnsafeProgram(f"reserve on tainted table {name}")
            r = m.get_var_binding(name)
            if not isinstance(r, TableHeap) or not r.alive:
                raise UnsafeProgram("reserve on dead table")
            bound_val = ev(bnode, m)
            if not is_int(bound_val) or bound_val < 0:
                raise UnsafeProgram("reserve bound must be non-negative integer")
            r.grow(bound_val)
        trips = 0
        while ev(s[1], m):
            m.push()
            try:
                for b in s[2]:
                    ex(b, m)
            finally:
                m.pop()
            trips += 1
            if trips > MAX_TRIPS:
                raise UnsafeProgram("loop ran away")
    elif t == "if":
        for c, body in s[1]:
            if ev(c, m):
                m.push()
                try:
                    for b in body:
                        ex(b, m)
                finally:
                    m.pop()
                return
        if s[2]:
            m.push()
            try:
                for b in s[2]:
                    ex(b, m)
            finally:
                m.pop()
    elif t == "print":
        for a in s[1]:
            ev(a, m)
    else:
        raise UnsafeProgram(f"bad stmt {t}")


def nilfree_names(stmts):
    out = []
    for s in stmts:
        if s[0] == "nilfree":
            out.append(s[1])
        elif s[0] == "while":
            out.extend(nilfree_names(s[2]))
        elif s[0] == "if":
            for _, b in s[1]:
                out.extend(nilfree_names(b))
            if s[2]:
                out.extend(nilfree_names(s[2]))
    return out


def free_vars(n, out=None):
    if out is None:
        out = set()
    t = n[0]
    if t == "var":
        out.add(n[1])
    elif t == "read":
        out.add(n[1])
        free_vars(n[2], out)
    elif t == "multi_read":
        out.add(n[1])
        for idx in n[2]:
            free_vars(idx, out)
    elif t == "table_lit":
        for val in n[2]:
            free_vars(val, out)
    elif t == "un":
        free_vars(n[2], out)
    elif t == "bin":
        free_vars(n[2], out)
        free_vars(n[3], out)
    return out


def written_prefix(root: TableHeap):
    p = 0
    while p in root.cells:
        p += 1
    return p


def collect_stmt_reads(stmts) -> Set[str]:
    reads = set()
    for s in stmts:
        t = s[0]
        if t in ("local", "assign"):
            reads |= free_vars(s[2])
        elif t == "store":
            reads.add(s[1])
            reads |= free_vars(s[2])
            reads |= free_vars(s[3])
        elif t == "multi_store":
            reads.add(s[1])
            for idx in s[2]:
                reads |= free_vars(idx)
            reads |= free_vars(s[3])
        elif t == "print":
            for a in s[1]:
                reads |= free_vars(a)
        elif t == "while":
            reads |= free_vars(s[1])
            reads |= collect_stmt_reads(s[2])
        elif t == "if":
            for cond, body in s[1]:
                reads |= free_vars(cond)
                reads |= collect_stmt_reads(body)
            if s[2]:
                reads |= collect_stmt_reads(s[2])
    return reads


class GlmLuaGenerator:
    def __init__(self, seed, mode="tables", inject_conflicts=True):
        self.r = random.Random(seed)
        self.mode = mode # Maintained to not crash fuzz.py runner arguments
        self.inject_conflicts = inject_conflicts
        self.reset()

    def reset(self):
        self.lines = []
        self.ind = 0
        self.vid = 0
        self.m = ScopeEnvironment()
        self.sink_vars = []
        self.active_ivs = set()

    def fresh(self):
        v = f"v{self.vid}"
        self.vid += 1
        return v

    def emit(self, line):
        self.lines.append("  " * self.ind + line)

    def emit_exec(self, stmt):
        self.emit(render_stmt(stmt))
        ex(stmt, self.m)

    def gen_block(self, depth, iv=None, n=None, in_loop=False, loop_reads=None) -> List:
        nodes = []
        if n is None:
            n = self.r.randint(1, 3)
        self.m.push()

        if iv:
            self.active_ivs.add(iv)

        try:
            for _ in range(n):
                nodes.extend(self.gen_stmt(depth, iv, in_loop, loop_reads))
        finally:
            if iv:
                self.active_ivs.discard(iv)
            self.m.pop()
        return nodes

    def int_vars(self):
        return self.m.visible(lambda v: is_int(v))

    def float_vars(self):
        return self.m.visible(lambda v: is_flt(v))

    def bool_vars(self):
        return self.m.visible(lambda v: is_bool(v))

    def str_vars(self):
        return self.m.visible(lambda v: isinstance(v, str))

    def table_names(self):
        return [
            name for name in self.m.visible(lambda v: isinstance(v, TableHeap))
            if self.m.can_safely_read(name)
        ]

    def live_roots(self):
        return sum(1 for th in self.m.heap.values() if th.alive)

    def safe_reads(self, elem="int"):
        out = []
        for name in self.table_names():
            root = self.m.get_var_binding(name)
            if root.elem != elem or not root.alive:
                continue
            for i in root.cells:
                out.append((name, i))
        return out

    def ensure_table(self, elem=None):
        names = self.table_names()
        if elem is not None:
            names = [n for n in names if self.m.get_var_binding(n).elem == elem]
        if names:
            return self.r.choice(names), []
        nodes = self.gen_table_decl(elem or self.r.choice(["int", "float"]))
        return nodes[0][1], nodes

    def gen_store_value(self, root: TableHeap):
        return self.gen_int_expr() if root.elem == "int" else self.gen_float_expr()

    def gen_initial_store(self, name):
        val = self.gen_store_value(self.m.get_var_binding(name))
        st = ("store", name, ("lit", 0), val)
        self.emit_exec(st)
        return st

    def gen_literal(self, typ):
        if typ == "int":
            return self.r.randint(-2, 15)
        if typ == "float":
            return round(self.r.uniform(-5.0, 15.0), 2)
        if typ == "str":
            return self.r.choice(["alpha", "beta", "gamma", "delta", "echo"])
        return self.r.choice([True, False])

    def gen_int_expr(self, depth=0):
        if depth >= 3 or self.r.random() < 0.35:
            reads = self.safe_reads("int")
            if reads and self.r.random() < 0.25:
                name, idx = self.r.choice(reads)
                return ("read", name, ("lit", idx))
            pool = self.int_vars()
            if pool and self.r.random() < 0.55:
                return ("var", self.r.choice(pool))
            return ("lit", self.r.randint(-2, 15))
        op = self.r.choices(["+", "-", "*", "//", "%"], [0.55, 0.30, 0.04, 0.065, 0.065])[0]
        if op in ("//", "%"):
            rhs = ("lit", self.r.choice([2, 3, 4, 5, -2, -3]))
            return ("bin", op, self.gen_int_expr(depth + 1), rhs)
        return ("bin", op, self.gen_int_expr(depth + 1), self.gen_int_expr(depth + 1))

    def gen_int_operand(self):
        reads = self.safe_reads("int")
        if reads and self.r.random() < 0.2:
            name, idx = self.r.choice(reads)
            return ("read", name, ("lit", idx))
        pool = self.int_vars()
        if pool and self.r.random() < 0.5:
            return ("var", self.r.choice(pool))
        return ("lit", self.r.randint(-2, 15))

    def gen_float_expr(self, depth=0):
        if depth >= 3 or self.r.random() < 0.35:
            reads = self.safe_reads("float")
            if reads and self.r.random() < 0.25:
                name, idx = self.r.choice(reads)
                return ("read", name, ("lit", idx))
            pool = self.float_vars()
            if pool and self.r.random() < 0.55:
                return ("var", self.r.choice(pool))
            return ("lit", self.gen_literal("float"))
        op = self.r.choices(["+", "-", "*", "/", "//", "%"], [0.4, 0.3, 0.05, 0.075, 0.075, 0.075])[0]
        if op in ("/", "//", "%"):
            rhs = ("lit", float(self.r.choice([2, 3, 4, 5, -2, -3])))
            return ("bin", op, self.gen_float_expr(depth + 1), rhs)
        return ("bin", op, self.gen_float_expr(depth + 1), self.gen_float_expr(depth + 1))

    def gen_bool_expr(self, depth=0):
        tables = self.table_names()
        kinds = ["cmpi", "cmpf", "eqb", "eqt", "not", "logic"]
        weights = [0.35, 0.15, 0.1, 0.1 if len(tables) >= 2 else 0.0, 0.1, 0.2]
        if depth >= 3:
            kinds, weights = ["cmpi", "cmpf", "eqb"], [0.6, 0.2, 0.2]
        k = self.r.choices(kinds, weights)[0]
        if k == "cmpi":
            op = self.r.choice(["<", ">", "<=", ">="])
            return ("bin", op, self.gen_int_operand(), self.gen_int_operand())
        if k == "cmpf":
            op = self.r.choice(["<", ">", "<=", ">="])
            pool = self.float_vars()
            def leaf():
                if pool and self.r.random() < 0.5:
                    return ("var", self.r.choice(pool))
                return ("lit", self.gen_literal("float"))
            return ("bin", op, leaf(), leaf())
        if k == "eqb":
            op = self.r.choice(["==", "~="])
            pool = self.bool_vars()
            a = (
                ("var", self.r.choice(pool))
                if pool and self.r.random() < 0.5
                else ("lit", self.r.choice([True, False]))
            )
            return ("bin", op, a, ("lit", self.r.choice([True, False])))
        if k == "eqt":
            op = self.r.choice(["==", "~="])
            same = [n for n in tables if self.m.get_var_binding(n).elem == self.m.get_var_binding(tables[0]).elem]
            if self.r.random() < 0.7 and len(same) >= 2:
                a, b = self.r.sample(same, 2)
            else:
                a = b = self.r.choice(same) if same else tables[0]
            return ("bin", op, ("var", a), ("var", b))
        if k == "not":
            return ("un", "not", self.gen_bool_expr(depth + 1))
        op = self.r.choice(["and", "or"])
        return ("bin", op, self.gen_bool_expr(depth + 1), self.gen_bool_expr(depth + 1))

    def gen_table_decl(self, elem=None):
        if elem is None:
            elem = self.r.choice(["int", "int", "float"])
        name = self.fresh()
        tag = "new" if elem == "int" else "newf"
        self.emit(f"local {name} = {{}}")
        self.m.allocate_table(name, elem=elem, local=True)
        nodes = [("local", name, (tag,))]
        nodes.append(self.gen_initial_store(name))

        tables = self.table_names()
        if len(tables) >= 2 and self.r.random() < 0.4:
            same = [t for t in tables if t != name and self.m.get_var_binding(t).elem == elem]
            if same:
                src = self.r.choice(same)
                alias = self.fresh()
                stmt = ("local", alias, ("var", src))
                self.emit_exec(stmt)
                nodes.append(stmt)
        return nodes

    def gen_scalar_decl(self, depth):
        typ = self.r.choice(["int", "int", "float", "str", "bool"])
        v = self.fresh()
        if typ == "int":
            e = self.gen_int_expr()
        elif typ == "float":
            e = self.gen_float_expr()
        elif typ == "bool":
            e = self.gen_bool_expr()
        else:
            pool = self.str_vars()
            e = (
                ("var", self.r.choice(pool))
                if pool and self.r.random() < 0.5
                else ("lit", self.gen_literal("str"))
            )
        self.emit_exec(("local", v, e))
        if len(self.m.scopes) == 1:
            self.sink_vars.append(v)
        return [("local", v, e)]

    def gen_local_decl(self, depth):
        if self.r.random() < 0.25 and self.live_roots() < MAX_ROOTS:
            return self.gen_table_decl()
        return self.gen_scalar_decl(depth)

    def gen_assignment(self, depth, avoid=None):
        if self.table_names() and self.r.random() < 0.15:
            name = self.r.choice(self.table_names())
            elem = self.m.get_var_binding(name).elem
            if self.r.random() < 0.5:
                same = [n for n in self.table_names() if self.m.get_var_binding(n).elem == elem]
                stmt = ("assign", name, ("var", self.r.choice(same)))
                self.emit_exec(stmt)
                return [stmt]
            tag = "new" if elem == "int" else "newf"
            stmt = ("assign", name, (tag,))
            self.emit_exec(stmt)
            st = ("store", name, ("lit", 0), self.gen_store_value(self.m.get_var_binding(name)))
            self.emit_exec(st)
            return [stmt, st]

        pools = {
            "int": self.int_vars(),
            "float": self.float_vars(),
            "str": self.str_vars(),
            "bool": self.bool_vars(),
        }
        avoid_set = self.active_ivs.copy()
        if avoid:
            avoid_set.add(avoid)
        pool = [(t, n) for t, ns in pools.items() for n in ns if n not in avoid_set]
        if not pool:
            return self.gen_scalar_decl(depth)
        typ, name = self.r.choice(pool)
        if typ == "int": e = self.gen_int_expr()
        elif typ == "float": e = self.gen_float_expr()
        elif typ == "bool": e = self.gen_bool_expr()
        else:
            spool = self.str_vars()
            e = ("var", self.r.choice(spool)) if spool else ("lit", self.gen_literal("str"))
        stmt = ("assign", name, e)
        self.emit_exec(stmt)
        return [stmt]

    def gen_store(self, iv=None):
        name, pre = self.ensure_table()
        if iv and self.r.random() < 0.65:
            key = ("var", iv)
        else:
            k = self.r.random()
            if k < 0.45:
                key = ("lit", self.r.randint(0, 15))
            elif k < 0.8:
                pool = [n for n in self.int_vars() if 0 <= self.m.get_var_binding(n) <= 12]
                if pool:
                    idx = ("bin", "+", ("var", self.r.choice(pool)), ("lit", self.r.randint(0, 4)))
                    key = ("bin", "%", idx, ("lit", 256))
                else:
                    key = ("lit", self.r.randint(0, 15))
            else:
                reads = [
                    (n, i) for (n, i) in self.safe_reads()
                    if 0 <= self.m.get_var_binding(n).cells[i] <= 15
                ]
                if reads:
                    rn, ri = self.r.choice(reads)
                    key = ("bin", "%", ("read", rn, ("lit", ri)), ("lit", 256))
                else:
                    key = ("lit", self.r.randint(0, 15))
        stmt = ("store", name, key, self.gen_store_value(self.m.get_var_binding(name)))
        self.emit_exec(stmt)
        return pre + [stmt]

    def gen_phantom_free(self) -> List:
        names = self.table_names()
        if not names: return []
        orig = self.r.choice(names)
        nodes = []
        alias = self.fresh()
        self.emit("do")
        self.ind += 1
        self.m.push()
        try:
            decl = ("local", alias, ("var", orig))
            self.emit_exec(decl)
            nodes.append(decl)
            drop = ("nilfree", alias)
            self.emit_exec(drop)
            nodes.append(drop)
        finally:
            self.m.pop()
            self.ind -= 1
            self.emit("end")
        if self.m.can_safely_read(orig):
            st = ("store", orig, ("lit", 1), self.gen_store_value(self.m.get_var_binding(orig)))
            self.emit_exec(st)
            nodes.append(st)
        return nodes

    def gen_shadow_drop(self) -> List:
        names = self.table_names()
        if not names: return []
        shadow_target = self.r.choice(names)
        elem = self.m.get_var_binding(shadow_target).elem
        nodes = []
        self.emit("do")
        self.ind += 1
        self.m.push()
        try:
            tag = "new" if elem == "int" else "newf"
            self.emit(f"local {shadow_target} = {{}}")
            self.m.allocate_table(shadow_target, elem=elem, local=True)
            nodes.append(("local", shadow_target, (tag,)))
            st = self.gen_initial_store(shadow_target)
            nodes.append(st)
            drop = ("nilfree", shadow_target)
            self.emit_exec(drop)
            nodes.append(drop)
        finally:
            self.m.pop()
            self.ind -= 1
            self.emit("end")
        if self.m.can_safely_read(shadow_target):
            st2 = ("store", shadow_target, ("lit", 2), self.gen_store_value(self.m.get_var_binding(shadow_target)))
            self.emit_exec(st2)
            nodes.append(st2)
        return nodes

    def gen_conditional_handoff(self, depth) -> List:
        names = self.table_names()
        if not names: return []
        t1 = self.r.choice(names)
        t2 = self.fresh()
        nodes = []
        decl = ("local", t2, ("var", t1))
        self.emit_exec(decl)
        nodes.append(decl)
        cond = self.gen_bool_expr()
        self.emit(f"if {render(cond)} then")
        self.ind += 1
        self.m.push()
        drop_a = ("nilfree", t1)
        self.emit_exec(drop_a)
        nodes.append(drop_a)
        self.m.pop()
        self.ind -= 1
        self.emit("else")
        self.ind += 1
        self.m.push()
        drop_b = ("nilfree", t2)
        self.emit_exec(drop_b)
        nodes.append(drop_b)
        self.m.pop()
        self.ind -= 1
        self.emit("end")
        aset_t1 = self.m.get_alias_set(t1)
        aset_t2 = self.m.get_alias_set(t2)
        if aset_t1: aset_t1.sites.add(NULL_ROOT)
        if aset_t2: aset_t2.sites.add(NULL_ROOT)
        return nodes

    def _gen_branch(self, depth, kw, cond, in_loop=False) -> Tuple[List, ScopeEnvironment]:
        mark = len(self.lines)
        self.emit("else" if cond is None else f"{kw} {render(cond)} then")
        self.ind += 1
        branch_env = self.m.snapshot()
        orig_env = self.m
        self.m = branch_env
        try:
            body = self.gen_block(depth + 1, in_loop=in_loop)
            if self.table_names() and self.r.random() < 0.35:
                body.extend(self.gen_nil_free())
        except UnsafeProgram:
            del self.lines[mark:]
            self.ind -= 1
            self.emit("else" if cond is None else f"{kw} {render(cond)} then")
            self.ind += 1
            body = []
            branch_env = orig_env.snapshot()
        finally:
            self.m = orig_env
            self.ind -= 1
        return body, branch_env

    def gen_if(self, depth, in_loop=False):
        conds = [self.gen_bool_expr()]
        while len(conds) < 3 and self.r.random() < 0.3:
            conds.append(self.gen_bool_expr())
        has_else = self.r.random() < 0.5
        orig_env = self.m.snapshot()
        branches, branch_envs = [], []
        for i, c in enumerate(conds):
            kw = "if" if i == 0 else "elseif"
            body, env = self._gen_branch(depth, kw, c, in_loop=in_loop)
            branches.append((c, body))
            branch_envs.append(env)
        else_body = None
        if has_else:
            else_body, env = self._gen_branch(depth, "else", None, in_loop=in_loop)
            branch_envs.append(env)
        else:
            branch_envs.append(orig_env)
        self.emit("end")
        final_env = orig_env.snapshot()
        for i in range(len(final_env.scopes)):
            orig_vars = set(orig_env.scopes[i].keys())
            for env in branch_envs:
                for sid, th in env.heap.items():
                    if sid in final_env.heap:
                        final_env.heap[sid].span = max(final_env.heap[sid].span, th.span)
                        final_env.heap[sid].cells.update(th.cells)
                        final_env.heap[sid].alive = final_env.heap[sid].alive and th.alive
                    else:
                        final_env.heap[sid] = th.copy()
                for var in orig_vars:
                    if var in env.alias_scopes[i]:
                        final_env.alias_scopes[i][var] = final_env.alias_scopes[i][var].union(env.alias_scopes[i][var])
                    if env.scopes[i].get(var) is NULL_SENTINEL:
                        final_env.scopes[i][var] = NULL_SENTINEL
        self.m = final_env
        return [("if", branches, else_body)]

    def conversion_reserves(self, body, guard, bound):
        mutated, body_locals, aliases = set(), set(), {guard}
        def scan(stmts):
            for s in stmts:
                if s[0] in ("assign", "nilfree"):
                    mutated.add(s[1])
                    if s[1] != guard: aliases.discard(s[1])
                elif s[0] == "local":
                    body_locals.add(s[1])
                    if MOVE_CHAINS and s[2][0] == "var" and s[2][1] in aliases:
                        aliases.add(s[1])
                elif s[0] == "while": scan(s[2])
                elif s[0] == "if":
                    for _, b in s[1]: scan(b)
                    if s[2]: scan(s[2])
        scan(body)
        if free_vars(bound) & mutated: return []
        reserves = []
        def collect(stmts):
            for s in stmts:
                if s[0] == "store":
                    key = s[2]
                    if key[0] == "var" and key[1] in aliases and s[1] not in mutated and s[1] not in body_locals:
                        reserves.append((s[1], bound))
                elif s[0] == "while": collect(s[2])
                elif s[0] == "if":
                    for _, b in s[1]: collect(b)
                    if s[2]: collect(s[2])
        collect(body)
        out, seen = [], set()
        for t, b in reserves:
            if t not in seen:
                seen.add(t)
                out.append((t, b))
        return out

    def _prefix_root(self):
        best = None
        for name in self.table_names():
            root = self.m.get_var_binding(name)
            if root.elem != "int" or not root.alive: continue
            p = written_prefix(root)
            if p >= 3 and (best is None or p > best[1]): best = (name, p)
        return best

    def gen_fill_loop(self, depth, in_loop=False):
        iv = self.fresh()
        i0 = 0 if self.r.random() < 0.8 else self.r.randint(1, 3)
        self.emit_exec(("local", iv, ("lit", i0)))
        nodes = [("local", iv, ("lit", i0))]
        sub = self.r.choices(["classic", "stride", "bump_first", "plus0", "rmw"], [0.4, 0.15, 0.15, 0.1, 0.2])[0]
        rmw_name = None
        if sub == "rmw":
            cand = self._prefix_root()
            if cand is None: sub = "classic"
            else:
                rmw_name, prefix = cand
                bound = ("lit", self.r.randint(1, min(prefix, 12)))
        if sub != "rmw":
            pool = [n for n in self.int_vars() if 1 <= self.m.get_var_binding(n) <= 24]
            if self.r.random() < 0.7 or not pool: bound = ("lit", self.r.randint(2, 12))
            else: bound = ("bin", "%", ("var", self.r.choice(pool)), ("lit", 16))
        step = 2 if sub == "stride" else 1
        snap = self.m.snapshot()
        self.emit(f"while {render(('bin', '<', ('var', iv), bound))} do")
        self.ind += 1
        body = []
        if sub == "rmw":
            st = ("store", rmw_name, ("var", iv), ("bin", "+", ("read", rmw_name, ("var", iv)), ("lit", self.r.randint(-3, 3))))
            body.append(st)
            self.emit_exec(st)
        elif sub == "bump_first":
            bump = ("assign", iv, ("bin", "+", ("var", iv), ("lit", step)))
            body.append(bump)
            self.emit_exec(bump)
            t, pre = self.ensure_table()
            st = ("store", t, ("var", iv), self.gen_store_value(self.m.get_var_binding(t)))
            body.extend(pre)
            body.append(st)
            self.emit_exec(st)
        elif sub == "plus0":
            p0 = ("assign", iv, ("bin", "+", ("var", iv), ("lit", 0)))
            body.append(p0)
            self.emit_exec(p0)
            t, pre = self.ensure_table()
            st = ("store", t, ("var", iv), self.gen_store_value(self.m.get_var_binding(t)))
            body.extend(pre)
            body.append(st)
            self.emit_exec(st)
        else:
            loop_reads = {iv} | free_vars(bound)
            body.extend(self.gen_block(depth + 1, iv, n=self.r.randint(1, 2), in_loop=True, loop_reads=loop_reads))
            if not any(s[0] == "store" and s[2] == ("var", iv) for s in body):
                t, pre = self.ensure_table()
                st = ("store", t, ("var", iv), self.gen_store_value(self.m.get_var_binding(t)))
                body.extend(pre)
                body.append(st)
                self.emit_exec(st)
        if sub != "bump_first":
            bump = ("assign", iv, ("bin", "+", ("var", iv), ("lit", step)))
            body.append(bump)
            self.emit_exec(bump)
        self.ind -= 1
        self.emit("end")
        reserves = self.conversion_reserves(body, iv, bound)
        while_node = ("while", ("bin", "<", ("var", iv), bound), body, reserves)
        nodes.append(while_node)
        dropped = set(nilfree_names(body))
        if dropped:
            accessed = collect_stmt_reads(body)
            for name in dropped & accessed:
                if snap.get_alias_set(name) is not None:
                    raise UnsafeProgram("Loop fixpoint back-edge violation: use-after-free")
        self.m = snap
        ex(while_node, self.m)
        for name in nilfree_names(body):
            aset = self.m.get_alias_set(name)
            if aset: aset.sites.add(NULL_ROOT)
        return nodes

    def gen_spice_loop(self, depth, in_loop=False):
        iv = self.fresh()
        self.emit_exec(("local", iv, ("lit", 0)))
        limit = self.r.randint(2, 10)
        spicy = self.gen_bool_expr()
        cond = ("bin", "and", ("bin", "<", ("var", iv), ("lit", limit)), spicy)
        snap = self.m.snapshot()
        self.emit(f"while {render(cond)} do")
        self.ind += 1
        loop_reads = free_vars(cond) | {iv}
        body = self.gen_block(depth + 1, iv, in_loop=True, loop_reads=loop_reads)
        bump = ("assign", iv, ("bin", "+", ("var", iv), ("lit", 1)))
        body.append(bump)
        self.emit_exec(bump)
        self.ind -= 1
        self.emit("end")
        dropped = set(nilfree_names(body))
        if dropped:
            accessed = collect_stmt_reads(body)
            for name in dropped & accessed:
                if snap.get_alias_set(name) is not None:
                    raise UnsafeProgram("Loop fixpoint back-edge violation: use-after-free")
        self.m = snap
        node = ("while", cond, body, [])
        ex(node, self.m)
        for name in nilfree_names(body):
            aset = self.m.get_alias_set(name)
            if aset: aset.sites.add(NULL_ROOT)
        return [("local", iv, ("lit", 0)), node]

    def gen_search_loop(self, depth):
        name, prefix = self._prefix_root()
        root = self.m.get_var_binding(name)
        j0 = self.r.randint(0, prefix - 3)
        runmax = root.cells[j0]
        cands = []
        for s in range(j0 + 1, prefix):
            if root.cells[s] > runmax: cands.append(s)
            runmax = max(runmax, root.cells[s])
        if not cands: return self.gen_fill_loop(depth)
        stop = self.r.choice(cands)
        k = root.cells[stop]
        j = self.fresh()
        self.emit_exec(("local", j, ("lit", j0)))
        cond = ("bin", "<", ("read", name, ("var", j)), ("lit", k))
        snap = self.m.snapshot()
        self.emit(f"while {render(cond)} do")
        self.ind += 1
        bump = ("assign", j, ("bin", "+", ("var", j), ("lit", 1)))
        self.emit_exec(bump)
        self.ind -= 1
        self.emit("end")
        dropped = set(nilfree_names([bump]))
        if dropped:
            accessed = collect_stmt_reads([bump])
            for name in dropped & accessed:
                if snap.get_alias_set(name) is not None:
                    raise UnsafeProgram("Loop fixpoint back-edge violation")
        self.m = snap
        node = ("while", cond, [bump], [])
        ex(node, self.m)
        for name in nilfree_names([bump]):
            aset = self.m.get_alias_set(name)
            if aset: aset.sites.add(NULL_ROOT)
        return [("local", j, ("lit", j0)), node]

    def gen_while(self, depth, in_loop=False):
        flavor = self.r.choices(["fill", "spice", "search"], [0.55, 0.25, 0.2 if self._prefix_root() else 0.0])[0]
        if flavor == "search": return self.gen_search_loop(depth)
        if flavor == "fill": return self.gen_fill_loop(depth, in_loop)
        return self.gen_spice_loop(depth, in_loop)

    def gen_nil_free(self, loop_reads=None) -> List:
        pool = self.table_names()
        if loop_reads:
            pool = [n for n in pool if self.m.can_safely_drop_in_loop(n, loop_reads)]
        if not pool: return []
        name = self.r.choice(pool)
        stmt = ("nilfree", name)
        self.emit_exec(stmt)
        return [stmt]

    def gen_inline_matrix(self):
        """Generates inline anonymous 2D tables with safe Lua dimensions."""
        v = self.fresh()
        rows, cols = self.r.randint(2, 4), self.r.randint(2, 4)
        inner_type = ("table", "int")
        table_ast = ("table_lit", inner_type, [
            ("table_lit", "int", [("lit", self.r.randint(0, 10)) for _ in range(cols)])
            for _ in range(rows)
        ])
        self.emit_exec(("local", v, table_ast))
        return v, rows, cols

    def gen_matrix_loop(self):
        """Generates Fast-Path matrix loop using proper abstract machine AST nodes."""
        t, rows, cols = self.gen_inline_matrix()
        i, j = self.fresh(), self.fresh()

        # Start at 1 to align with Lua table_lit initialization bounds!
        self.emit_exec(("local", i, ("lit", 1)))
        snap = self.m.snapshot()

        cond_outer = ("bin", "<=", ("var", i), ("lit", rows))
        self.emit(f"while {render(cond_outer)} do")
        self.ind += 1

        decl_j = ("local", j, ("lit", 1))
        self.emit_exec(decl_j)

        cond_inner = ("bin", "<=", ("var", j), ("lit", cols))
        self.emit(f"while {render(cond_inner)} do")
        self.ind += 1

        store = ("multi_store", t, [("var", i), ("var", j)], ("bin", "+", ("var", i), ("var", j)))
        self.emit_exec(store)

        bump_j = ("assign", j, ("bin", "+", ("var", j), ("lit", 1)))
        self.emit_exec(bump_j)

        self.ind -= 1
        self.emit("end")

        bump_i = ("assign", i, ("bin", "+", ("var", i), ("lit", 1)))
        self.emit_exec(bump_i)

        self.ind -= 1
        self.emit("end")

        # Build the exact nodes and run them through Python ex() at once to stay in sync
        inner_loop = ("while", cond_inner, [store, bump_j], [])
        outer_body = [decl_j, inner_loop, bump_i]
        outer_loop = ("while", cond_outer, outer_body, [])

        self.m = snap
        ex(outer_loop, self.m)

    def gen_stmt(self, depth, iv=None, in_loop=False, loop_reads=None):
        weights = [
            ("decl", 0.16),
            ("assign", 0.12),
            ("store", 0.20 if self.table_names() else 0.05),
            ("if", 0.14 if depth < 3 else 0.0),
            ("while", 0.18 if depth < 3 else 0.0),
            ("phantom_free", 0.07 if self.table_names() else 0.0),
            ("shadow_drop", 0.07 if self.table_names() else 0.0),
            ("handoff", 0.06 if self.table_names() else 0.0),
        ]
        pick = self.r.choices([w[0] for w in weights], [w[1] for w in weights])[0]
        if pick == "decl": return self.gen_local_decl(depth)
        if pick == "assign": return self.gen_assignment(depth, avoid=iv)
        if pick == "store": return self.gen_store(iv)
        if pick == "if": return self.gen_if(depth, in_loop)
        if pick == "phantom_free": return self.gen_phantom_free()
        if pick == "shadow_drop": return self.gen_shadow_drop()
        if pick == "handoff": return self.gen_conditional_handoff(depth)
        return self.gen_while(depth, in_loop)

    def emit_sinks(self):
        for v in self.sink_vars[:10]:
            self.emit_exec(("print", [("var", v)]))
        args = []
        top = [
            (n, v) for n, v in self.m.scopes[0].items()
            # Only print pure scalars or 1D tables of scalars to prevent diffs failing on 'table: 0x...' 
            if isinstance(v, TableHeap) and v.alive and self.m.can_safely_read(n) and isinstance(v.elem, str)
        ]
        for name, root in top:
            unwritten = [i for i in range(root.span) if i not in root.cells]
            picks = self.r.sample(unwritten, min(2, len(unwritten)))
            picks += self.r.sample(sorted(root.cells), min(2, len(root.cells)))
            args.extend(("read", name, ("lit", i)) for i in picks)
            if len(args) >= 8:
                break
        if args:
            self.emit_exec(("print", args[:8]))

    def gen_conflict(self):
        """Intentionally breaks First-Touch Homogeneity."""
        t, rows, cols = self.gen_inline_matrix()
        self.emit("-- EXPECT_CONFLICT")
        self.emit(f"{t}[1][1] = \"type_conflict_poison\"")

    def _gen_once(self):
        self.reset()
        for t in ("int", "float", "str", "bool"):
            v = f"root_{t}"
            self.emit_exec(("local", v, ("lit", self.gen_literal(t))))
            self.sink_vars.append(v)

        for _ in range(self.r.randint(10, 18)):
            self.gen_stmt(0)
            if self.table_names() and self.r.random() < 0.12:
                self.gen_nil_free()

        # Inject the Fast-Path Matrix loop logic proactively
        for _ in range(self.r.randint(1, 3)):
            try:
                self.gen_matrix_loop()
            except UnsafeProgram:
                pass

        if self.inject_conflicts and self.r.random() < 0.15:
            self.gen_conflict()
            # Return immediately so we don't accidentally evaluate the strict failure in Python
            return "\n".join(self.lines) + "\n"

        self.emit_sinks()
        return "\n".join(self.lines) + "\n"

    def generate(self):
        for _ in range(40):
            try:
                return self._gen_once()
            except (UnsafeProgram, RecursionError):
                continue
        return "print(0)\n"
