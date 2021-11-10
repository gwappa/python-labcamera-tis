# MIT License
#
# Copyright (c) 2021 Keisuke Sehara
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from cython.operator cimport dereference as deref, preincrement as inc
from libcpp cimport bool as cppbool
from libcpp.vector cimport vector as stdvector
from libcpp.string cimport string as stdstring
from libc.stdint cimport uint8_t, uint32_t, int64_t, uint64_t

cdef extern from "windows.h" nogil:
    cdef struct SIZE:
        long cx, cy

    cdef enum COINIT:
        pass

    ctypedef unsigned char BYTE

cdef extern from "windows.h" namespace "COINIT" nogil:
    cdef COINIT COINIT_APARTMENTTHREADED
    cdef COINIT COINIT_MULTITHREADED
    cdef COINIT COINIT_DISABLE_OLE1DDE
    cdef COINIT COINIT_SPEED_OVER_MEMORY

cdef extern from "tisudshl.h" nogil:
    cdef cppclass smart_ptr[T]:
        T& operator*()

    cdef cppclass smart_com[T]:
        bint operator==(T* p)
        bint operator!=(T* p)
        smart_com[T] operator=(T* p)

cdef extern from "tisudshl.h" namespace "DShowLib:Grabber" nogil:
    ctypedef smart_ptr[FrameQueueBuffer]       tFrameQueueBufferPtr
    ctypedef stdvector[tFrameQueueBufferPtr]   tFrameQueueBufferList
    ctypedef stdvector[VideoCaptureDeviceItem] tVidCapDevList
    ctypedef smart_ptr[tVidCapDevList]         tVidCapDevListPtr
    ctypedef stdvector[VideoFormatItem]        tVidFmtList
    ctypedef smart_ptr[tVidFmtList]            tVidFmtListPtr

cdef extern from "tisudshl.h" namespace "DShowLib" nogil:
    bint InitLibrary(COINIT coinit)
    void ExitLibrary()

    cdef cppclass Error:
        cppbool   isError()
        cppbool   isSuccess()
        stdstring toString()

    ## values are copied from "udshl/simplectypes.h"
    cdef enum tColorformatEnum:
        eInvalidColorformat =  0 # DO NOT USE
        eRGB32              =  1 # 32 bit BGRA
        eRGB24              =  2 # 24 bit BGR
        eRGB565             =  3 # 16 bit 5-6-5 BGR @deprecated in favor of eRGB32
        eRGB555             =  4 # 16 bit 5-5-5 BGR @deprecated in favor of eRGB32
        eRGB8               =  5 # 8 bit grayscale (i.e. Y8)
        eY8                 =  5 # alias for 'eRGB8'
        eUYVY               =  6 # 16 bit YUV top-down
        eY800               =  7 # 8 bit grayscale top-down
        eYGB1               =  8 # 10/16 bit grayscale top-down, bits ordered per pixel [76543210______98]
        eYGB0               =  9 # 10/16 bit grayscale top-down, bits ordered per pixel [10______98765432]
        eBY8                = 10 # Bayer Y800
        eY16                = 11 # 16 bit grayscale top-down, each pixel being represented by an unsigned 16 bit integer
        eRGB64              = 12 # 16 bit * (B, G, R, A)

    cdef cppclass FrameTypeInfo:
        SIZE             dim
        size_t           buffersize
        uint32_t         getBitsPerPixel()
        tColorformatEnum getColorformat()

    cdef cppclass VideoFormatItem:
        stdstring     toString()
        stdstring     getColorformatString()
        FrameTypeInfo getFrameType()

    cdef cppclass VideoCaptureDeviceItem:
        ##
        #   returns the unique name of the device.
        #   (only available for those that return a S/N)
        #
        stdstring getUniqueName()
        stdstring getBaseName()
        int64_t   getSerialNumber()

    cdef cppclass IVCDPropertyItems:
        pass

    cdef cppclass IVCDPropertyItem:
        pass

    cdef cppclass IVCDPropertyElement:
        pass

    cdef cppclass IVCDPropertyInterface:
        smart_com[T]& QueryInterface[T](smart_com[T]& rval)

    cdef cppclass IVCDAbsoluteValueProperty:
        pass

    cdef cppclass IVCDButtonProperty:
        pass

    cdef cppclass IVCDRangeProperty:
        pass

    cdef cppclass IVCDMapStringsProperty: # inherits IVCDRangeProperty
        pass

    cdef cppclass IVCDSwitchProperty:
        cppbool getSwitch()
        void    setSwitch(cppbool val)

    ##
    #   used in zero-copy notification
    #
    cdef cppclass IFrame:
        BYTE *getPtr()

    ##
    #   used in frame queues
    #
    cdef cppclass FrameQueueBuffer:
        void *getUserPointer()

    cdef cppclass GrabberSinkType:
        pass

    cdef cppclass FrameNotificationSinkListener:
        pass

    ##
    #   zero-copy notification sink
    #
    cdef cppclass FrameNotificationSink(GrabberSinkType):
        @staticmethod
        smart_ptr[FrameNotificationSink] create(FrameNotificationSinkListener& listener,
                                                const FrameTypeInfo& type)

    cdef cppclass FrameQueueSinkListener:
        pass

    ##
    #   queued frame buffer sink
    #
    cdef cppclass FrameQueueSink(GrabberSinkType):
        @staticmethod
        smart_ptr[FrameQueueSink] create(FrameQueueSinkListener& listener,
                                         const FrameTypeInfo& type)
        ##
        #   can only be called after the sink is successfully connected
        #   to a grabber during `prepare`
        #
        Error   allocAndQueueBuffers(size_t count)
        cppbool isCancelRequested()

        tFrameQueueBufferPtr popOutputQueueBuffer()
        Error                queueBuffer(tFrameQueueBufferPtr& buffer)

    ctypedef smart_com[IVCDPropertyItem]          tIVCDPropertyItemPtr
    ctypedef stdvector[tIVCDPropertyItemPtr]      tVCDPropertyItemArray
    ctypedef smart_com[IVCDPropertyElement]       tIVCDPropertyElementPtr
    ctypedef stdvector[tIVCDPropertyElementPtr]   tVCDPropertyElementArray
    ctypedef smart_com[IVCDPropertyInterface]     tIVCDPropertyInterfacePtr
    ctypedef stdvector[tIVCDPropertyInterfacePtr] tVCDPropertyInterfaceArray

    cdef cppclass Grabber:
        ##
        #   constructs a new Grabber object.
        #
        Grabber()

        Error                  getLastError()

        tVidCapDevListPtr      getAvailableVideoCaptureDevices()
        VideoCaptureDeviceItem getDev()

        #
        # for the following procedures, the boolean return values are the status of success.
        #
        cppbool openDevByUniqueName(const stdstring& dev)
        cppbool isDevOpen()
        cppbool isDevValid()
        cppbool closeDev()

        ## frame rate-related
        double  getFPS()
        cppbool setFPS(double fps)

        ## trigger-related
        cppbool hasExternalTrigger()
        cppbool getExternalTrigger()
        cppbool setExternalTrigger(cppbool value)

        ## format-related
        tVidFmtListPtr  getAvailableVideoFormats()
        VideoFormatItem getVideoFormat()
        cppbool         setVideoFormat(const stdstring& fmt)

        ## property-related
        smart_com[IVCDPropertyItems] getAvailableVCDProperties()

        ## capture-related

        ##
        #   must be called _before_ `prepareLive` (i.e. during IDLE)
        #
        cppbool setSinkType(smart_ptr[GrabberSinkType] newsink)

        ##
        #   IDLE-->READY
        #
        cppbool prepareLive(cppbool render)

        ##
        #   IDLE/READY-->RUNNING
        #
        cppbool startLive(cppbool show)

        ##
        #   RUNNING-->READY
        #
        cppbool suspendLive()

        ##
        #   READY/RUNNING-->IDLE
        #
        cppbool stopLive()

##
#   this is the "plan B" as the current Cython implementation does not allow
#   operator overload for '->'
#
cdef extern from "property_utils.hpp" nogil:
    ctypedef smart_com[IVCDPropertyItems]     COMPropertyItemsPtr
    ctypedef smart_com[IVCDPropertyItem]      COMPropertyItemPtr
    ctypedef smart_com[IVCDPropertyElement]   COMPropertyElementPtr
    ctypedef smart_com[IVCDPropertyInterface] COMPropertyInterfacePtr

    ctypedef smart_com[IVCDAbsoluteValueProperty] AbsoluteValueInterfacePtr
    ctypedef smart_com[IVCDButtonProperty]        ButtonInterfacePtr
    ctypedef smart_com[IVCDRangeProperty]         RangeInterfacePtr
    ctypedef smart_com[IVCDMapStringsProperty]    MapStringsInterfacePtr
    ctypedef smart_com[IVCDSwitchProperty]        SwitchInterfacePtr

    tVCDPropertyItemArray    getPropertiesItems(COMPropertyItemsPtr& properties)

    stdstring                getPropertyName(COMPropertyItemPtr& property)
    tVCDPropertyElementArray getPropertyElements(COMPropertyItemPtr& property)

    stdstring                  getElementName(COMPropertyElementPtr& element)
    tVCDPropertyInterfaceArray getElementInterfaces(COMPropertyElementPtr& element)
    smart_com[T]               queryInterface[T](COMPropertyInterfacePtr& obj, smart_com[T]& ref)

    void pushButton(ButtonInterfacePtr& button)

    bint getSwitch(SwitchInterfacePtr& switch)
    void setSwitch(SwitchInterfacePtr& switch, bint& val)

    long getValueRangeMin(RangeInterfacePtr& rng)
    long getValueRangeMax(RangeInterfacePtr& rng)
    long getRangedValue(RangeInterfacePtr& rng)
    void setRangedValue(RangeInterfacePtr& rng, long& val)

    double getAbsoluteValueMin(AbsoluteValueInterfacePtr& value)
    double getAbsoluteValueMax(AbsoluteValueInterfacePtr& value)
    double getAbsoluteValue(AbsoluteValueInterfacePtr& value)
    void   setAbsoluteValue(AbsoluteValueInterfacePtr& value, double& val)

    stdstring getCurrentString(MapStringsInterfacePtr& options)
    stdvector[stdstring] getStringOptions(MapStringsInterfacePtr& options)
    void setCurrentString(MapStringsInterfacePtr& options, const stdstring& newval)

import warnings as _warnings
import logging as _logging
import sys as _sys
from collections import namedtuple as _namedtuple
import numpy as _np

class TISDeviceWarning(UserWarning):
    pass

class TISDeviceStatusWarning(TISDeviceWarning):
    pass

def check_retval(bint ret, msg, type=TISDeviceWarning):
    if bool(ret) == False:
        if isinstance(type, BaseException):
            raise type(msg)
        else:
            _warnings.warn(msg, type)
        return bool(ret)

cdef class _LibraryBackend:
    def __cinit__(self):
        check_retval(InitLibrary(COINIT_MULTITHREADED),
                     "Failed to init TIS_UDSHL DShowLib library",
                     RuntimeError)
        LOGGER.info("loaded TIS_UDSHL")

    def __dealloc__(self):
        ExitLibrary()
        LOGGER.info("unloaded TIS_UDSHL")

_logging.basicConfig(level=_logging.INFO,
                     format="[%(asctime)s %(name)s] %(levelname)s: %(message)s")
LOGGER = _logging.getLogger("ks-labcamera-tis")
LOGGER.setLevel(_logging.INFO)

BACKEND = _LibraryBackend() # handles InitLibrary() and ExitLibrary() calls

DEFAULT_ENCODING     = 'utf-8'
DEFAULT_VIDEO_FORMAT = 'Y16 (640x480)'
DEBUG_FORMATS        = True
DEBUG_PROPERTIES     = True

cdef str as_python_str(stdstring src):
    return (<bytes>(src.c_str())).decode(DEFAULT_ENCODING)

cdef class ColorFormat:
    """the interface for tColorformatEnum"""
    cdef tColorformatEnum _fmt

    def __cinit__(self):
        self._fmt = eInvalidColorformat

    def __dealloc__(self):
        pass

    cdef _load(self, tColorformatEnum fmt):
        self._fmt = fmt

    def __str__(self):
        return f"ColorFormat({int(self._fmt)})"

    @property
    def ffmpeg_style(self):
        if self._fmt == eRGB24:
            return "rgb24"
        elif self._fmt == eRGB32:
            return "rgba"
        elif self._fmt == eY800:
            return "gray"
        elif self._fmt == eY16:
            return "gray16le" # FIXME: assumes the little-endian environment
        else:
            raise NotImplementedError(f"color format unimplemented for ffmpeg: {self}")

    @property
    def dtype(self):
        if self._fmt == eRGB24:
            return _np.uint8
        elif self._fmt == eRGB32:
            return _np.uint8
        elif self._fmt == eY800:
            return _np.uint8
        elif self._fmt == eY16:
            return _np.uint16 # FIXME: assumes the little-endian environment
        else:
            raise NotImplementedError(f"color format unimplemented for dtype: {self}")

    @property
    def per_pixel(self):
        if self._fmt == eRGB24:
            return 3
        elif self._fmt == eRGB32:
            return 4
        elif self._fmt == eY800:
            return 1
        elif self._fmt == eY16:
            return 1
        else:
            raise NotImplementedError(f"color format unimplemented for per-pixel # of values: {self}")

cdef class FrameTypeDescriptor:
    cdef FrameTypeInfo _type
    cdef object        _colorfmt

    def __cinit__(self):
        self._colorfmt = ColorFormat()

    def __dealloc__(self):
        pass

    cdef _load(self, FrameTypeInfo type):
        self._type = type
        self._colorfmt._load(self._type.getColorformat())

    @property
    def color_format(self):
        return self._colorfmt

    @property
    def buffer_size(self):
        """the size of the image buffer to be required, in bytes."""
        return self._type.buffersize

    @property
    def width(self):
        return self._type.dim.cx

    @property
    def height(self):
        return self._type.dim.cy

    @property
    def per_pixel(self):
        return self._colorfmt.per_pixel

    @property
    def shape(self):
        """the shape of a single frame when it is converted into a NumPy array."""
        return (self.height, self.width, self.per_pixel)

    @property
    def dtype(self):
        """the data type of the frame when it is converted into a NumPy array."""
        return self._colorfmt.dtype

    @property
    def numpy_formatter(self):
        return dict(dtype=self.dtype, shape=self.shape)

# the state of the device.
#
# IDLE --(prepare)--> READY --(start)--> RUNNING
# └-------------------------(start)------┘
#
# RUNNING --(suspend)--> READY --(stop)--> IDLE
# └----------------------------(stop)-----┘
cdef enum DeviceState:
    NODEV   = -1
    IDLE    = 0
    READY   = 1
    RUNNING = 2

cdef class Device:
    """the main interface to the ImagingSource camera."""

    cdef Grabber    *_grabber
    cdef DeviceState _state
    cdef object      _props

    @classmethod
    def list_names(cls):
        cdef Grabber *grabber = new Grabber()
        ret = []
        cdef stdvector[VideoCaptureDeviceItem] devs  = deref(grabber.getAvailableVideoCaptureDevices())
        for dev in devs:
            ret.append(as_python_str(dev.getUniqueName()))
        del grabber
        return tuple(ret)

    def __cinit__(self, name: str):
        """
        creates a Grabber context, and opens the device with `name` being its "unique name".

        `name` must be one of the string values being obtained from the `list_names()` method.
        RuntimeError will be thrown in case of any errors.
        """
        cdef bint ret

        # open
        self._grabber = new Grabber()
        self._state   = NODEV
        ret = self._grabber.openDevByUniqueName(name.encode(DEFAULT_ENCODING))
        if bool(ret) == False:
            raise RuntimeError("failed to open device: " + name)
        self._state   = IDLE

        # setup video formats
        fmts = self.list_video_formats()
        if DEFAULT_VIDEO_FORMAT in fmts:
            self.video_format = DEFAULT_VIDEO_FORMAT

        # set up properties
        self._props = Properties(self)

    def __dealloc__(self):
        del self._grabber

    @property
    def model_name(self):
        return as_python_str(self._grabber.getDev().getBaseName())

    @property
    def serial_number(self):
        return hex(int(self._grabber.getDev().getSerialNumber()))

    @property
    def unique_name(self):
        return as_python_str(self._grabber.getDev().getUniqueName())

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
            # anyway
            self._state = NODEV

    def list_video_formats(self):
        ret = []
        cdef stdvector[VideoFormatItem] formats  = deref(self._grabber.getAvailableVideoFormats())
        for fmt in formats:
            ret.append(as_python_str(fmt.toString()))
        return tuple(ret)

    @property
    def video_format(self):
        return as_python_str(self._grabber.getVideoFormat().toString())

    @video_format.setter
    def video_format(self, fmt: str):
        check_retval(self._grabber.setVideoFormat(fmt.encode(DEFAULT_ENCODING)),
                     "failed to update video format to: '" + fmt + "'",
                     type=RuntimeError)
        if DEBUG_FORMATS:
            colorfmt   = as_python_str(self._grabber.getVideoFormat().getColorformatString())
            fmtindex   = int(self._grabber.getVideoFormat().getFrameType().getColorformat())
            buffersize = int(self._grabber.getVideoFormat().getFrameType().buffersize)
            LOGGER.info(f"video format--> {self.video_format}, color: {colorfmt} (fmtindex), buffersize={buffersize}")

    ##
    #  trigger/rate/strobe settings
    #
    @property
    def has_trigger(self):
        return bool(self._grabber.hasExternalTrigger())

    @property
    def triggered(self):
        return self._grabber.getExternalTrigger()

    @triggered.setter
    def triggered(self, bint val):
        check_retval(self._grabber.setExternalTrigger(val),
                     "Grabber::setExternalTrigger() failed")

    def software_trigger(self):
        """generates a software trigger and sends it to the device."""
        self._props['Trigger']['Software Trigger'].run()

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

    @property
    def has_strobe(self):
        return ('Strobe' in self._props.keys()) \
               and ('Enable' in self._props['Strobe'])

    @property
    def strobe(self):
        return (self._props['Strobe']['Enable'].value == True) \
               and (self._props['Strobe']['Mode'].value == 'exposure')

    @strobe.setter
    def strobe(self, val):
        val = bool(val)
        self._props['Strobe']['Enable'].value = val
        if val == True:
           self._props['Strobe']['Mode'].value = 'exposure'

    ##
    #   exposure settings
    #
    @property
    def has_exposure(self):
        return ('Exposure' in self._props.keys())

    @property
    def has_auto_exposure(self):
        return ('Exposure' in self._props.keys()) \
                and ('Auto' in self._props['Exposure'].keys())

    @property
    def auto_exposure(self):
        """current status of the auto-exposure mode in Boolean."""
        return self._props['Exposure']['Auto'].value

    @auto_exposure.setter
    def auto_exposure(self, val):
        self._props['Exposure']['Auto'].value = bool(val)

    @property
    def exposure_us(self):
        """current exposure setting in microseconds, as an integer.

        Note it returns some (possibly invalid) value even when
        the auto-exposure mode is turned on.
        """
        exposure_sec = float(self._props["Exposure"]["Value"].value)
        return int(round(exposure_sec * 1e6))

    @exposure_us.setter
    def exposure_us(self, val):
        """sets the manual exposure in microseconds.

        Note it does _not_ disable the auto-exposure mode even when it has been on.
        """
        val = int(round(val))
        self._props["Exposure"]["Value"].value = float(val) / 1e6

    @property
    def exposure_range_us(self):
        """range of possible exposures in microseconds, as a tuple of integers (min, max)."""
        return tuple(int(round(float(v) * 1e6)) for v in self._props['Exposure']['Value'].range)

    ##
    #   gain settings
    #
    @property
    def has_gain(self):
        return ('Gain' in self._props.keys())

    @property
    def has_auto_gain(self):
        return ('Gain' in self._props.keys()) \
                and ('Auto' in self._props['Gain'])

    @property
    def auto_gain(self):
        """returns the status of the auto-gain mode in Boolean."""
        return self._props['Gain']['Auto'].value

    @auto_gain.setter
    def auto_gain(self, val):
        self._props['Gain']['Auto'].value = bool(val)

    @property
    def gain(self):
        """returns the current value of manual gain.

        Note it returns some (possibly invalid) value even when
        the auto-gain mode is turned on.
        """
        return self._props['Gain']['Value'].value

    @gain.setter
    def gain(self, val):
        """sets the value of manual gain.

        Note it does _not_ disable the auto-gain mode even when it has been on.
        """
        self._props['Gain']['Value'].value = float(val)

    @property
    def gain_range(self):
        """range of possible values of gain, as a tuple of floats (min, max)."""
        return self._props['Gain']['Value'].range

    ##
    #   gamma settings
    #
    @property
    def has_gamma(self):
        return ('Gamma' in self._props.keys())

    @property
    def has_auto_gamma(self):
        return False # FIXME

    @property
    def gamma(self):
        """returns the current value of manual gamma.

        Note it returns some (maybe invalid) value even when the auto-gamma mode is turned on.
        """
        return self._props['Gamma']['Value'].value

    @gamma.setter
    def gamma(self, val):
        """sets the value of manual gamma.

        Note it does _not_ disable the auto-gamma mode even when it has been on.
        """
        self._props['Gamma']['Value'].value = float(val)

    @property
    def props(self):
        return self._props

    ## TODO: implement prepare/live/sink/callback

cdef class Properties:
    """the pythonic interface to 'VCDProperties' controls."""
    cdef Grabber *_grabber
    cdef object   _items

    def __cinit__(self, Device device):
        self._grabber = device._grabber
        self._items   = {}

        cdef stdvector[tIVCDPropertyItemPtr] items = getPropertiesItems(self._grabber.getAvailableVCDProperties())
        # print(f"enumerate {int(items.size())} properties:", flush=True)
        for item in items:
            prop = Property()._load(item)
            self._items[prop.name] = prop

    def __dealloc__(self):
        pass

    def __len__(self):
        return len(self._items)

    def __getitem__(self, key):
        return self._items[key]

    def keys(self):
        return tuple(key for key in self._items.keys())

    def values(self):
        return tuple(val for val in self._items.values())

    def items(self):
        return tuple((key, val) for key, val in self._items.items())

cdef class Property:
    """the interface to a 'VCDProperty'"""
    cdef tIVCDPropertyItemPtr _prop
    cdef object               _elems

    def __cinit__(self):
        self._elems = {}

    cdef _load(self, tIVCDPropertyItemPtr prop):
        self._prop = prop
        cdef stdvector[tIVCDPropertyElementPtr] elems = getPropertyElements(prop)
        # print(f"property '{self.name}': found {int(elems.size())} elements.", flush=True)
        for _elem in elems:
            elem = PropertyElement(self)._load(_elem)
            self._elems[elem.name] = elem
        return self

    def __dealloc__(self):
        pass

    @property
    def name(self):
        return getPropertyName(self._prop).decode(DEFAULT_ENCODING)

    def __len__(self):
        return len(self._elems)

    def __getitem__(self, key):
        return self._elems[key]

    def keys(self):
        return tuple(key for key in self._elems.keys())

    def values(self):
        return tuple(val for val in self._elems.values())

    def items(self):
        return tuple((key, val) for key, val in self._elems.items())

cdef class PropertyElement:
    """the interface to an element of a VCDProperty."""
    cdef object                  _prop
    cdef tIVCDPropertyElementPtr _elem
    cdef object                  _interfaces

    def __cinit__(self, prop):
        self._prop       = prop
        self._interfaces = {}

    def __dealloc__(self):
        pass

    cdef _load(self, tIVCDPropertyElementPtr elem):
        self._elem = elem
        cdef stdvector[tIVCDPropertyInterfacePtr] interfaces = getElementInterfaces(elem)
        for interface in interfaces:
            item = PropertyElementInterface(self._prop, self)._load(interface)
            self._interfaces[item.spec] = item
        return self

    @property
    def name(self):
        return getElementName(self._elem).decode(DEFAULT_ENCODING)

    @property
    def type(self):
        keys = self.interfaces
        for typ in ("Switch", "Button", "AbsoluteValue", "MapStrings"):
            if typ in keys:
                return typ
        return "Unknown"

    @property
    def interfaces(self):
        return tuple(self._interfaces.keys())

    def _get_interface(self, key):
        return self._interfaces[key]

    @property
    def value(self):
        """available only when 'Switch', 'AbsoluteValue' or 'MapStrings' interfaces exist for this element."""
        keys = self.interfaces
        if 'Switch' in keys:
            return self._interfaces['Switch'].get_switch_unsafe()

        elif 'AbsoluteValue' in keys:
            return self._interfaces['AbsoluteValue'].get_absolute_value_unsafe()

        elif 'Range' in keys:
            return self._interfaces['Range'].get_range_value_unsafe()

        elif 'MapStrings' in keys:
            return self._interfaces['MapStrings'].get_current_string_unsafe()

        else:
            raise NotImplementedError(f"'{self.name}' of '{self._prop.name}' does not have a value")

    @value.setter
    def value(self, value):
        """available only when 'Switch', 'AbsoluteValue', 'Range' or 'MapStrings' interfaces exist for this element."""
        keys = self.interfaces
        if 'Switch' in keys:
            self._interfaces["Switch"].set_switch_unsafe(value)

        elif 'AbsoluteValue' in keys:
            # TODO: ensure range
            self._interfaces["AbsoluteValue"].set_absolute_value_unsafe(value)

        elif 'MapStrings' in self._interfaces:
            # TODO: ensure range
            self._interfaces["MapStrings"].set_current_string_unsafe(value)

        elif 'Range' in keys:
            # TODO: ensure range
            self._interfaces["Range"].set_range_value_unsafe(value)

        else:
            raise NotImplementedError(f"'{self.name}' of '{self._prop.name}' does not have a value")

    @property
    def range(self):
        """available only when 'AbsoluteValue', 'Range' or 'MapStrings' interfaces exist for this element.

        returns
        -------
        - (min, max) in case of 'Range'
        - a tuple of available options, in case of 'MapStrings' (not implemented for the time being)
        """
        keys = self.interfaces
        if 'AbsoluteValue' in keys:
            return self._interfaces["AbsoluteValue"].get_absolute_value_range_unsafe()

        elif 'MapStrings' in keys:
            return self._interfaces["MapStrings"].get_string_options_unsafe()

        elif 'Range' in keys:
            return self._interfaces["Range"].get_range_values_unsafe()

        else:
            raise NotImplementedError(f"'{self.name}' of '{self._prop.name}' does not have a range")

    def run(self):
        """available only when 'Button' interface exists for this element."""
        if not 'Button' in self._interfaces.keys():
            raise NotImplementedError(f"cannot run '{self.name}' of '{self._prop.name}'")
        self._interfaces["Button"].push_button_unsafe()

cdef class PropertyElementInterface:
    cdef object _prop
    cdef object _elem
    cdef tIVCDPropertyInterfacePtr _base

    cdef object _spec
    cdef AbsoluteValueInterfacePtr _value
    cdef ButtonInterfacePtr        _button
    cdef RangeInterfacePtr         _range
    cdef MapStringsInterfacePtr    _options
    cdef SwitchInterfacePtr        _switch

    def __cinit__(self, prop, elem):
        self._prop = prop
        self._elem = elem
        self._spec = "Unknown"

        self._value   = NULL
        self._button  = NULL
        self._range   = NULL
        self._options = NULL
        self._switch  = NULL

    def __dealloc__(self):
        pass

    cdef _load(self, tIVCDPropertyInterfacePtr interface):
        self._base = interface
        spec = self._specify()
        if DEBUG_PROPERTIES == True:
            log = LOGGER.info
        else:
            log = LOGGER.debug
        log(f"{self._prop.name}/{self._elem.name}: {spec}")
        return self

    cdef _specify(self):
        self._value = queryInterface(self._base, self._value)
        if self._value != NULL:
            self._spec = "AbsoluteValue"
            return self._spec

        self._button = queryInterface(self._base, self._button)
        if self._button != NULL:
            self._spec = "Button"
            return self._spec

        self._range = queryInterface(self._base, self._range)
        if self._range != NULL:
            self._options = queryInterface(self._base, self._options)
            if self._options != NULL:
                self._range = NULL
                self._spec  = "MapStrings"
            else:
                self._spec = "Range"
            return self._spec

        self._switch = queryInterface(self._base, self._switch)
        if self._switch != NULL:
            self._spec = "Switch"
            return self._spec

        return self._spec

    @property
    def spec(self):
        return self._spec

    def get_switch_unsafe(self):
        return getSwitch(self._switch)

    def set_switch_unsafe(self, cppbool newval):
        setSwitch(self._switch, newval)

    def get_range_values_unsafe(self):
        cdef long m = getValueRangeMin(self._range)
        cdef long M = getValueRangeMax(self._range)
        return (int(m), int(M))

    def get_range_value_unsafe(self):
        return getRangedValue(self._range)

    def set_range_value_unsafe(self, long newval):
        setRangedValue(self._range, newval)

    def get_absolute_value_range_unsafe(self):
        cdef double m = getAbsoluteValueMin(self._value)
        cdef double M = getAbsoluteValueMax(self._value)
        return (m, M)

    def get_absolute_value_unsafe(self):
        return getAbsoluteValue(self._value)

    def set_absolute_value_unsafe(self, double newval):
        setAbsoluteValue(self._value, newval)

    def get_string_options_unsafe(self):
        ret = []
        for option in getStringOptions(self._options):
            ret.append(as_python_str(option))
        return tuple(ret)

    def get_current_string_unsafe(self):
        return as_python_str(getCurrentString(self._options))

    def set_current_string_unsafe(self, newval):
        setCurrentString(self._options, newval.encode(DEFAULT_ENCODING))

    def push_button_unsafe(self):
        with nogil:
            pushButton(self._button)
