from cython.operator cimport dereference as deref, preincrement as inc
from libcpp.vector cimport vector as stdvector
from libcpp.string cimport string as stdstring

cdef extern from "objbase.h" nogil:
    cdef enum COINIT:
        pass

cdef extern from "objbase.h" namespace "COINIT" nogil:
    cdef COINIT COINIT_APARTMENTTHREADED
    cdef COINIT COINIT_MULTITHREADED
    cdef COINIT COINIT_DISABLE_OLE1DDE
    cdef COINIT COINIT_SPEED_OVER_MEMORY

cdef extern from "tisudshl.h" nogil:
    cdef cppclass smart_ptr[T]:
        T& operator*()

cdef extern from "tisudshl.h" namespace "DShowLib:Grabber" nogil:
    ctypedef stdvector[VideoCaptureDeviceItem] tVidCapDevList
    ctypedef smart_ptr[tVidCapDevList]         tVidCapDevListPtr

cdef extern from "tisudshl.h" namespace "DShowLib" nogil:
    bint InitLibrary(COINIT coinit)

    cdef cppclass VideoCaptureDeviceItem:
        ##
        #   returns the unique name of the device.
        #   (only available for those that return a S/N)
        #
        stdstring getUniqueName()

    cdef cppclass Grabber:
        ##
        #   constructs a new Grabber object.
        #
        Grabber()

        tVidCapDevListPtr getAvailableVideoCaptureDevices()

cdef bint INITIALIZED = 0

cpdef initialize():
    global INITIALIZED
    if INITIALIZED == False:
        INITIALIZED = InitLibrary(COINIT_MULTITHREADED)
        if INITIALIZED == False:
            raise RuntimeError("failed to initialize DShowLib library")

cdef class GrabberContext:
    cdef Grabber *_grabber

    def __cinit__(self):
        initialize()
        self._grabber = new Grabber()

    def __dealloc__(self):
        del self._grabber

    @property
    def devices(self):
        ret = []
        cdef stdvector[VideoCaptureDeviceItem] devs  = deref(self._grabber.getAvailableVideoCaptureDevices())
        for dev in devs:
            bname = <bytes> (dev.getUniqueName().c_str())
            ret.append(bname.decode())
        return tuple(ret)
