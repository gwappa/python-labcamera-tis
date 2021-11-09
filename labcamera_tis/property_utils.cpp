/*
 *  MIT License
 *
 *  Copyright (c) 2021 Keisuke Sehara
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
*/

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
