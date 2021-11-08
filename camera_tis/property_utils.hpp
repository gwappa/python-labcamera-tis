#ifndef PROPERTY_UTILS_HPP_
#include <tisudshl.h>

typedef smart_com<DShowLib::IVCDPropertyItems>     COMPropertyItemsPtr;
typedef smart_com<DShowLib::IVCDPropertyItem>      COMPropertyItemPtr;
typedef smart_com<DShowLib::IVCDPropertyElement>   COMPropertyElementPtr;
typedef smart_com<DShowLib::IVCDPropertyInterface> COMPropertyInterfacePtr;

typedef smart_com<DShowLib::IVCDAbsoluteValueProperty> AbsoluteValueInterfacePtr;
typedef smart_com<DShowLib::IVCDButtonProperty>        ButtonInterfacePtr;
typedef smart_com<DShowLib::IVCDRangeProperty>         RangeInterfacePtr;
typedef smart_com<DShowLib::IVCDMapStringsProperty>    MapStringsInterfacePtr;
typedef smart_com<DShowLib::IVCDSwitchProperty>        SwitchInterfacePtr;

DShowLib::tVCDPropertyItemArray
getPropertiesItems(COMPropertyItemsPtr& properties);

std::string
getPropertyName(COMPropertyItemPtr& property);

DShowLib::tVCDPropertyElementArray
getPropertyElements(COMPropertyItemPtr& property);

std::string
getElementName(COMPropertyElementPtr& element);

DShowLib::tVCDPropertyInterfaceArray
getElementInterfaces(COMPropertyElementPtr& element);

template<class T>
smart_com<T> queryInterface(COMPropertyInterfacePtr& obj, smart_com<T>& ref) {
    return obj->QueryInterface(ref);
}

void pushButton(ButtonInterfacePtr& btn);

bool getSwitch(SwitchInterfacePtr& sw);
void setSwitch(SwitchInterfacePtr& sw, bool& newval);

long getValueRangeMin(RangeInterfacePtr& rng);
long getValueRangeMax(RangeInterfacePtr& rng);
long getRangedValue(RangeInterfacePtr& rng);
void setRangedValue(RangeInterfacePtr& rng, long& newval);

double getAbsoluteValueMin(AbsoluteValueInterfacePtr& value);
double getAbsoluteValueMax(AbsoluteValueInterfacePtr& value);
double getAbsoluteValue(AbsoluteValueInterfacePtr& value);
void   setAbsoluteValue(AbsoluteValueInterfacePtr& value, double& newval);

std::string
getCurrentString(MapStringsInterfacePtr& option);
std::vector<std::string>
getStringOptions(MapStringsInterfacePtr& option);
void
setCurrentString(MapStringsInterfacePtr& option, const std::string& newval);

#define PROPERTY_UTILS_HPP_
#endif
