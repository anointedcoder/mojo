from memory.unsafe import Pointer

def your_function(a,b):
    let c = a
    #c = b

    if c != b:
        let d = b
        print(d)

def your_function2():
    let x: Int = 32
    let y: Float64  = 17.0

    let z: Float32
    if x != 0:
        z = 1.0
    else:
        z = foo()

    print(z)

def foo() -> Float32:
    return 3.14

struct MyPair:
    var first: Int
    var second: Int

    fn __init__(inout self, first: Int, second: Int):
        self.first = first
        self.second = second

    fn __lt__(self, rhs: MyPair) -> Bool:
        return self.first < rhs.first or 
                (self.first == rhs.first and
                  self.second < rhs.second)
def pair_test() -> Bool:
    let p = MyPair(1,2)
    # return p < 4
    return True

struct Complex:
    var re: Float32
    var im: Float32

    fn __init__(inout self,x: Float32):
        """Construct a complex number given a real number."""
        self.re   = x
        self.im  = 0.0

    fn __init__(inout self, r:Float32, i: Float32):
        """Construct a complex number given it's real and imaginary components."""
        self.re = r
        self.im  = i

struct HeapArray:
    var data: Pointer[Int]
    var size: Int
    var cap: Int

    fn __init__(inout self):
        self.cap = 16
        self.size = 0
        self.data  = Pointer[Int].alloc(self.cap)

    fn __init__(inout self, size: Int, val: Int):
        self.cap  = size * 2
        self.size  = size
        self.data  = Pointer[Int].alloc(self.cap)

        for i in range(self.size):
            self.data.store(i,val)

    fn __del__(owned self):
        self.data.free()

    fn dump(self):
        print_no_newline("[")
        for i in range(self.size):
            if i > 0:
                print_no_newline(", ")
            print_no_newline(self.data.load(i))
        print("]")

    fn __copyinit__(inout self, other: Self):
        """Makes the Array copyable."""
        self.cap = other.cap
        self.size = other.size
        self.data = Pointer[Int].alloc(self.cap)

        for i in range(self.size):
            self.data.store(i,other.data.load(i))

struct SomethingBig:
    var id_number:Int
    var huge: HeapArray

    fn __init__(inout self, id: Int):
        self.huge  = HeapArray(1000,0)
        self.id_number = id

    # self is passed in by-reference for mutation as described above
    fn set_id(inout self, number: Int):
        self.id_number = number

    # Arguments like self are passed as borrowed by default
    fn print_id(self):  
        print(self.id_number)

#An example where the magic function __iadd__ tries to modify self

struct MyInt:
    var value: Int

    fn __init__(inout self,v: Int):
        self.value = v

    fn __copyinit__(inout self, Other: MyInt):
        self.value = Other.value

    # self and rhs are both immutable in __iadd__.
    fn __add__(self, rhs: MyInt)-> MyInt:
        return MyInt(self.value + rhs.value)
    # ... but this cannot work for __iadd__
    # Uncomment to see the error:
    #fn __iadd__(self, rhs: MyInt):
    #  self = self + rhs # ERROR cannot assign to self
    # When Uncommented we get a compile error.
    # The problem is that fn args are immutable, ie. borrowed
    # Adding the inout keyword makes the arg mutable
    # Now this works

    fn __iadd__(inout self, rhs: MyInt):
        self = self + rhs

# Transfer arguments, owned argument convention
# It used for functions that want to take exclusive ownership over a value
# Example move-only type like a unique Pointer
# Transfer of ownership to some other function using the ^ operator
# To make a function support taking ownership,
# the owned argument is used

fn take_ptr(owned p: UniquePointer):
    print("take_ptr")
    print(p.ptr)

fn use_ptr(borrowed p: UniquePointer):
    print("use_ptr")
    print(p.ptr)
fn work_with_unique_ptrs():
    let p  = UniquePointer(100)
    use_ptr(p) # Pass to borrowing function
    take_ptr(p^) # Pass ownership of the p value to another function

    # Uncomment to see an ERROR:
    # use_ptr(p) # ERROR: p is no longer valid here!


struct UniquePointer:
    var ptr: Int

    fn __init__(inout self, ptr: Int):
        self.ptr = ptr

    fn __moveinit__(inout self, owned existing: Self):
        self.ptr = existing.ptr

    fn __del__(owned self):
        self.ptr = 0


#Python integration
# Importing Python modules

from python import Python


def python_integration():
    # This is equivalent to Python's import numpy as np
    let np = Python.import_module("numpy")
    # Now use numpy as if writing in Python
    array = np.array([1,2,3])
    print(array)    

# Mojo Types in python
# Converst implicitly to into python objects

def type_print():
    try:
         Python.add_to_path(".")
         Python.add_to_path("./examples")
         Python.add_to_path("./examples/python_files")
         tp = Python.import_module("type_printer")
         if tp:
            tp.type_printer([0,3], (False,True), 4, "Orange", 3.4)
         else:
            print("Module type_printer not found")
    except e:
        print(e.value)
        pass

from python.object import PythonObject
def python_dict():
    
    try:
        dictionary = Python.dict()
        dictionary["fruit"] = "Apple"
        dictionary["starch"]  = "Potato"
        var keys: PythonObject = ["fruit", "starch","protein"]
        var N: Int = keys.__len__().__index__()
        print(N,"items")

        for i in range(N):
            if Python.is_type(dictionary.get(keys[i]), Python.none()):
                print(keys[i], "is not in the dictionary")
            else:
                print(keys[i], "is included")
    except e:
        print(e.value)
         
   
    



fn main() raises:
    #your_function(2,3)
    your_function2()
    pair_test()
    var a  = HeapArray(3,1)
    a.dump()
    # var b = HeapArray(4,2)
    # b.dump()
    # a.dump()
    # Code below works due to implementation of __copyinit__
    var b = a

    b.dump()
    a.dump()

    # Example of using MyInt mutable Arguments
    var x: MyInt = 42
    x += 1
    print(x.value)  # Prints 43 as expected

    #However ...
    let y  = x
    # Uncomment to see the ERROR
    # y += 1 # ERROR: cannot mutate 'let' value
    # OF course you can declare multiple inout values

    fn swap(inout lhs: Int, inout rhs: Int):
        let tmp  = lhs
        lhs = rhs

    var x2 = 42
    var y2 = 12

    print(x2,y2) # Prints 42 , 12
    swap(x2,y2)
    print(x2,y2) # Prints 12, 42

    work_with_unique_ptrs()
    python_integration()
    
    type_print()

    python_dict()