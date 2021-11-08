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
    ctypedef stdvector[VideoFormatItem]        tVidFmtList
    ctypedef smart_ptr[tVidFmtList]            tVidFmtListPtr

cdef extern from "tisudshl.h" namespace "DShowLib" nogil:
    bint InitLibrary(COINIT coinit)

    cdef cppclass VideoFormatItem:
        stdstring toString()

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

        #
        # for the following procedures, the boolean return values are the status of success.
        #
        bint              openDevByUniqueName(const stdstring& dev)
        bint              isDevOpen()
        bint              isDevValid()
        bint              closeDev()

        ## frame rate-related
        double getFPS()
        bint   setFPS(double fps)

        ## trigger-related
        bint hasExternalTrigger()
        bint getExternalTrigger()
        bint setExternalTrigger(bint value)

        ## format-related
        tVidFmtListPtr  getAvailableVideoFormats()
        VideoFormatItem getVideoFormat()
        bint            setVideoFormat(const stdstring& fmt)

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

DEFAULT_VIDEO_FORMAT = 'Y16 (640x480)'

cdef class Device:
    cdef Grabber *_grabber
    cdef bint    _triggered

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

        # open
        self._grabber = new Grabber()
        ret = self._grabber.openDevByUniqueName(name.encode('utf-8'))
        if bool(ret) == False:
            raise RuntimeError("failed to open device: " + name)

        # setup trigger status
        if self.has_trigger:
            self._triggered = False
            # since there is no such method 'isTriggerEnabled()',
            # we need to sync the internal state by explicityly calling `EnableTrigger()`.
            self.triggered  = False

        # setup video formats
        fmts = self.list_video_formats()
        if DEFAULT_VIDEO_FORMAT in fmts:
            self.video_format = DEFAULT_VIDEO_FORMAT

    def __dealloc__(self):
        del self._grabber

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
                         "Grabber::closeDev() failed")

    @property
    def has_trigger(self):
        return bool(self._grabber.hasExternalTrigger())

    @property
    def triggered(self):
        # assumes that the _triggered attribute has been already set
        # upon initialization of the object
        return self._triggered

    @triggered.setter
    def triggered(self, bint val):
        if check_retval(self._grabber.setExternalTrigger(val),
                        "Grabber::setExternalTrigger() failed") == True:
            self._triggered = val

    @property
    def frame_rate(self):
        """returns the frame rate in frames-per-second (FPS)."""
        return self._grabber.getFPS()

    @frame_rate.setter
    def frame_rate(self, double fps):
        """updates the frame rate to the specified value,
        given as frames-per-second (FPS)."""
        if self._grabber.setFPS(fps) == False:
            raise RuntimeError(f"failed to set frame rate to: {fps:.1f}")

    def list_video_formats(self):
        ret = []
        cdef stdvector[VideoFormatItem] formats  = deref(self._grabber.getAvailableVideoFormats())
        for fmt in formats:
            bname = <bytes> (fmt.toString().c_str())
            ret.append(bname.decode())
        return tuple(ret)

    @property
    def video_format(self):
        bname = <bytes> self._grabber.getVideoFormat().toString().c_str()
        return bname.decode()

    @video_format.setter
    def video_format(self, fmt: str):
        if self._grabber.setVideoFormat(fmt.encode('utf-8')) == False:
            raise RuntimeError("failed to update video format to: '" + fmt + "'")
