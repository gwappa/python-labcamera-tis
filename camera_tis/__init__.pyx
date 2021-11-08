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
        bint              openDevByUniqueName(const stdstring& dev)
        bint              isDevOpen()
        bint              isDevValid()
        bint              closeDev()


import warnings as _warnings

class TISDeviceWarning(UserWarning):
    pass

class TISDeviceStatusWarning(TISDeviceWarning):
    pass

cdef bint INITIALIZED = 0

cpdef void initialize():
    global INITIALIZED
    if INITIALIZED == False:
        INITIALIZED = InitLibrary(COINIT_MULTITHREADED)
        if INITIALIZED == False:
            raise RuntimeError("failed to initialize DShowLib library")

# cdef char *as_c_str(s: str):
#     return s.encode('utf8')[0]

def check_retval(bint ret, msg, warntype=TISDeviceWarning):
    if bool(ret) == False:
        _warnings.warn(msg, warntype)
    return bool(ret)

cdef class Device:
    cdef Grabber *_grabber

    @classmethod
    def list_names(cls):
        initialize()
        cdef Grabber *grabber = new Grabber()
        ret = []
        cdef stdvector[VideoCaptureDeviceItem] devs  = deref(grabber.getAvailableVideoCaptureDevices())
        for dev in devs:
            bname = <bytes> (dev.getUniqueName().c_str())
            ret.append(bname.decode())
        del grabber
        return tuple(ret)

    def __cinit__(self, name: str):
        """
        creates a Grabber context, and opens the device with `name` being its "unique name".

        `name` must be one of the string values being obtained from the `list_names()` method.
        RuntimeError will be thrown in case of any errors.
        """
        initialize()
        cdef bint ret
        self._grabber = new Grabber()
        ret = self._grabber.openDevByUniqueName(name.encode('utf-8'))
        if bool(ret) == False:
            raise RuntimeError("failed to open device: " + name)

    def _is_open(self):
        """returns whether the device is currently open.

        But use `is_valid()` instead to test whether this Device object can access
        to its associated device."""
        return bool(self._grabber.isDevOpen())

    def is_valid(self):
        """returns whether this Device object has access to its associated physical device."""
        return bool(self._grabber.isDevValid())

    def close(self):
        """closes the device"""
        cdef bint ret
        if self._is_open():
            check_retval(self._grabber.closeDev(),
                         "Grabber::closeDev() returned false")

    def __dealloc__(self):
        del self._grabber
