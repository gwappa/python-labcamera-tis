from cython.operator cimport dereference as deref, preincrement as inc
from libcpp cimport bool as cppbool
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

    cdef cppclass smart_com[T]:
        bint operator==(T* p)
        bint operator!=(T* p)
        smart_com[T] operator=(T* p)

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
        bint getSwitch()
        void setSwitch(bint val)

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

        ## property-related
        smart_com[IVCDPropertyItems] getAvailableVCDProperties()

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

DEFAULT_ENCODING     = 'utf-8'
DEFAULT_VIDEO_FORMAT = 'Y16 (640x480)'

cdef class Device:
    """the main interface to the ImagingSource camera."""

    cdef Grabber *_grabber
    cdef object  _props

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
        ret = self._grabber.openDevByUniqueName(name.encode(DEFAULT_ENCODING))
        if bool(ret) == False:
            raise RuntimeError("failed to open device: " + name)

        # setup video formats
        fmts = self.list_video_formats()
        if DEFAULT_VIDEO_FORMAT in fmts:
            self.video_format = DEFAULT_VIDEO_FORMAT

        # set up properties
        self._props = Properties(self)

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
        return self._grabber.getExternalTrigger()

    @triggered.setter
    def triggered(self, bint val):
        check_retval(self._grabber.setExternalTrigger(val),
                     "Grabber::setExternalTrigger() failed")

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
        if self._grabber.setVideoFormat(fmt.encode(DEFAULT_ENCODING)) == False:
            raise RuntimeError("failed to update video format to: '" + fmt + "'")

    @property
    def props(self):
        return self._props

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
        print(f"{self._prop.name}/{self._elem.name}: {spec}")
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
            ret.append((<bytes>(option.c_str())).decode(DEFAULT_ENCODING))
        return tuple(ret)

    def get_current_string_unsafe(self):
        return getCurrentString(self._options).decode(DEFAULT_ENCODING)

    def set_current_string_unsafe(self, newval):
        setCurrentString(self._options, newval.encode(DEFAULT_ENCODING))

    def push_button_unsafe(self):
        with nogil:
            pushButton(self._button)
