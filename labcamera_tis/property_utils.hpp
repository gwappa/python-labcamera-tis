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
