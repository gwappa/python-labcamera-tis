#include "property_utils.hpp"

DShowLib::tVCDPropertyItemArray getPropertiesItems(COMPropertyItemsPtr& properties) {
    return properties->getItems();
}

std::string getPropertyName(COMPropertyItemPtr& property) {
    return property->getName();
}

DShowLib::tVCDPropertyElementArray getPropertyElements(COMPropertyItemPtr& property) {
    return property->getElements();
}

std::string getElementName(COMPropertyElementPtr& element) {
    return element->getName();
}

DShowLib::tVCDPropertyInterfaceArray getElementInterfaces(COMPropertyElementPtr& element) {
    return element->getInterfaces();
}

void pushButton(ButtonInterfacePtr& btn) {
    btn->push();
}

bool getSwitch(SwitchInterfacePtr& sw) {
    return sw->getSwitch();
}

void setSwitch(SwitchInterfacePtr& sw, bool& newval) {
    sw->setSwitch(newval);
}

long getValueRangeMin(RangeInterfacePtr& rng) {
    return rng->getRangeMin();
}

long getValueRangeMax(RangeInterfacePtr& rng) {
    return rng->getRangeMax();
}

long getRangedValue(RangeInterfacePtr& rng) {
    return rng->getValue();
}

void setRangedValue(RangeInterfacePtr& rng, long& newval) {
    rng->setValue(newval);
}

double getAbsoluteValueMin(AbsoluteValueInterfacePtr& value) {
    return value->getRangeMin();
}

double getAbsoluteValueMax(AbsoluteValueInterfacePtr& value) {
    return value->getRangeMax();
}

double getAbsoluteValue(AbsoluteValueInterfacePtr& value) {
    return value->getValue();
}

void setAbsoluteValue(AbsoluteValueInterfacePtr& value, double& newval) {
    value->setValue(newval);
}

std::string getCurrentString(MapStringsInterfacePtr& option) {
    return option->getString();
}

std::vector<std::string> getStringOptions(MapStringsInterfacePtr& option) {
    return option->getStrings();
}

void setCurrentString(MapStringsInterfacePtr& option, const std::string& newval) {
    option->setString(newval);
}
