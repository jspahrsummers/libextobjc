//
//  EXTADTTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 19.06.12.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTADTTest.h"

ADT(Color,
    constructor(Red),
    constructor(Green),
    constructor(Blue),
    constructor(Gray, double alpha),
    constructor(Other, double r, double g, double b),
    constructor(Named, __unsafe_unretained NSString *name)
);

ADT(Multicolor,
    constructor(OneColor, const ColorT c),
    constructor(TwoColor, const ColorT first, const ColorT second),
    constructor(RecursiveColor, const MulticolorT *mc)
);

ADT(MaxConstructors,
    constructor(MaxParams1, int C1P1, int C1P2, int C1P3, int C1P4, int C1P5, int C1P6, int C1P7, int C1P8, int C1P9, int C1P10, int C1P11, int C1P12, int C1P13, int C1P14, int C1P15, int C1P16, int C1P17, int C1P18, int C1P19),
    constructor(MaxParams2, int C2P1, int C2P2, int C2P3, int C2P4, int C2P5, int C2P6, int C2P7, int C2P8, int C2P9, int C2P10, int C2P11, int C2P12, int C2P13, int C2P14, int C2P15, int C2P16, int C2P17, int C2P18, int C2P19),
    constructor(MaxParams3, int C3P1, int C3P2, int C3P3, int C3P4, int C3P5, int C3P6, int C3P7, int C3P8, int C3P9, int C3P10, int C3P11, int C3P12, int C3P13, int C3P14, int C3P15, int C3P16, int C3P17, int C3P18, int C3P19),
    constructor(MaxParams4, int C4P1, int C4P2, int C4P3, int C4P4, int C4P5, int C4P6, int C4P7, int C4P8, int C4P9, int C4P10, int C4P11, int C4P12, int C4P13, int C4P14, int C4P15, int C4P16, int C4P17, int C4P18, int C4P19),
    constructor(MaxParams5, int C5P1, int C5P2, int C5P3, int C5P4, int C5P5, int C5P6, int C5P7, int C5P8, int C5P9, int C5P10, int C5P11, int C5P12, int C5P13, int C5P14, int C5P15, int C5P16, int C5P17, int C5P18, int C5P19),
    constructor(MaxParams6, int C6P1, int C6P2, int C6P3, int C6P4, int C6P5, int C6P6, int C6P7, int C6P8, int C6P9, int C6P10, int C6P11, int C6P12, int C6P13, int C6P14, int C6P15, int C6P16, int C6P17, int C6P18, int C6P19),
    constructor(MaxParams7, int C7P1, int C7P2, int C7P3, int C7P4, int C7P5, int C7P6, int C7P7, int C7P8, int C7P9, int C7P10, int C7P11, int C7P12, int C7P13, int C7P14, int C7P15, int C7P16, int C7P17, int C7P18, int C7P19),
    constructor(MaxParams8, int C8P1, int C8P2, int C8P3, int C8P4, int C8P5, int C8P6, int C8P7, int C8P8, int C8P9, int C8P10, int C8P11, int C8P12, int C8P13, int C8P14, int C8P15, int C8P16, int C8P17, int C8P18, int C8P19),
    constructor(MaxParams9, int C9P1, int C9P2, int C9P3, int C9P4, int C9P5, int C9P6, int C9P7, int C9P8, int C9P9, int C9P10, int C9P11, int C9P12, int C9P13, int C9P14, int C9P15, int C9P16, int C9P17, int C9P18, int C9P19),
    constructor(MaxParams10, int C10P1, int C10P2, int C10P3, int C10P4, int C10P5, int C10P6, int C10P7, int C10P8, int C10P9, int C10P10, int C10P11, int C10P12, int C10P13, int C10P14, int C10P15, int C10P16, int C10P17, int C10P18, int C10P19),
    constructor(MaxParams11, int C11P1, int C11P2, int C11P3, int C11P4, int C11P5, int C11P6, int C11P7, int C11P8, int C11P9, int C11P10, int C11P11, int C11P12, int C11P13, int C11P14, int C11P15, int C11P16, int C11P17, int C11P18, int C11P19),
    constructor(MaxParams12, int C12P1, int C12P2, int C12P3, int C12P4, int C12P5, int C12P6, int C12P7, int C12P8, int C12P9, int C12P10, int C12P11, int C12P12, int C12P13, int C12P14, int C12P15, int C12P16, int C12P17, int C12P18, int C12P19),
    constructor(MaxParams13, int C13P1, int C13P2, int C13P3, int C13P4, int C13P5, int C13P6, int C13P7, int C13P8, int C13P9, int C13P10, int C13P11, int C13P12, int C13P13, int C13P14, int C13P15, int C13P16, int C13P17, int C13P18, int C13P19),
    constructor(MaxParams14, int C14P1, int C14P2, int C14P3, int C14P4, int C14P5, int C14P6, int C14P7, int C14P8, int C14P9, int C14P10, int C14P11, int C14P12, int C14P13, int C14P14, int C14P15, int C14P16, int C14P17, int C14P18, int C14P19),
    constructor(MaxParams15, int C15P1, int C15P2, int C15P3, int C15P4, int C15P5, int C15P6, int C15P7, int C15P8, int C15P9, int C15P10, int C15P11, int C15P12, int C15P13, int C15P14, int C15P15, int C15P16, int C15P17, int C15P18, int C15P19),
    constructor(MaxParams16, int C16P1, int C16P2, int C16P3, int C16P4, int C16P5, int C16P6, int C16P7, int C16P8, int C16P9, int C16P10, int C16P11, int C16P12, int C16P13, int C16P14, int C16P15, int C16P16, int C16P17, int C16P18, int C16P19),
    constructor(MaxParams17, int C17P1, int C17P2, int C17P3, int C17P4, int C17P5, int C17P6, int C17P7, int C17P8, int C17P9, int C17P10, int C17P11, int C17P12, int C17P13, int C17P14, int C17P15, int C17P16, int C17P17, int C17P18, int C17P19),
    constructor(MaxParams18, int C18P1, int C18P2, int C18P3, int C18P4, int C18P5, int C18P6, int C18P7, int C18P8, int C18P9, int C18P10, int C18P11, int C18P12, int C18P13, int C18P14, int C18P15, int C18P16, int C18P17, int C18P18, int C18P19),
    constructor(MaxParams19, int C19P1, int C19P2, int C19P3, int C19P4, int C19P5, int C19P6, int C19P7, int C19P8, int C19P9, int C19P10, int C19P11, int C19P12, int C19P13, int C19P14, int C19P15, int C19P16, int C19P17, int C19P18, int C19P19)
);

@implementation EXTADTTest

- (void)testRed {
    ColorT c = Color.Red();
    XCTAssertEqual(c.tag, Red, @"");
    XCTAssertEqualObjects(NSStringFromColor(c), @"Red", @"");
    XCTAssertTrue(ColorEqualToColor(c, Color.Red()), @"");
}

- (void)testGray {
    ColorT c = Color.Gray(0.75);
    XCTAssertEqual(c.tag, Gray, @"");
    XCTAssertEqualWithAccuracy(c.alpha, 0.75, 0.0001, @"");
    XCTAssertEqualObjects(NSStringFromColor(c), @"Gray { alpha = 0.75 }", @"");
    XCTAssertTrue(ColorEqualToColor(c, Color.Gray(0.75)), @"");
}

- (void)testOther {
    ColorT c = Color.Other(1.0, 0.5, 0.25);
    XCTAssertEqual(c.tag, Other, @"");
    XCTAssertEqualWithAccuracy(c.r, 1.0, 0.0001, @"");
    XCTAssertEqualWithAccuracy(c.g, 0.5, 0.0001, @"");
    XCTAssertEqualWithAccuracy(c.b, 0.25, 0.0001, @"");
    XCTAssertEqualObjects(NSStringFromColor(c), @"Other { r = 1, g = 0.5, b = 0.25 }", @"");
    XCTAssertTrue(ColorEqualToColor(c, Color.Other(1.0, 0.5, 0.25)), @"");
}

- (void)testNamed {
    ColorT c = Color.Named(@"foobar");
    XCTAssertEqual(c.tag, Named, @"");
    XCTAssertEqualObjects(c.name, @"foobar", @"");
    XCTAssertEqualObjects(NSStringFromColor(c), @"Named { name = foobar }", @"");
    XCTAssertTrue(ColorEqualToColor(c, Color.Named(@"foobar")), @"");
}

- (void)testMulticolor {
    MulticolorT c = Multicolor.TwoColor(Color.Gray(0.5), Color.Other(0.25, 0.5, 0.75));
    XCTAssertEqual(c.tag, TwoColor, @"");

    XCTAssertEqual(c.first.tag, Gray, @"");
    XCTAssertEqualWithAccuracy(c.first.alpha, 0.5, 0.0001, @"");
    XCTAssertTrue(ColorEqualToColor(c.first, Color.Gray(0.5)), @"");

    XCTAssertEqual(c.second.tag, Other, @"");
    XCTAssertEqualWithAccuracy(c.second.r, 0.25, 0.0001, @"");
    XCTAssertEqualWithAccuracy(c.second.g, 0.5, 0.0001, @"");
    XCTAssertEqualWithAccuracy(c.second.b, 0.75, 0.0001, @"");
    XCTAssertTrue(ColorEqualToColor(c.second, Color.Other(0.25, 0.5, 0.75)), @"");

    XCTAssertTrue(MulticolorEqualToMulticolor(c, Multicolor.TwoColor(Color.Gray(0.5), Color.Other(0.25, 0.5, 0.75))), @"");
}

- (void)testRecursiveMulticolor {
    MulticolorT c1 = Multicolor.OneColor(Color.Red());
    MulticolorT c2 = Multicolor.RecursiveColor(&c1);
//    XCTAssertEqual(*c2.mc, c1, @"");

    XCTAssertTrue(MulticolorEqualToMulticolor(c2, Multicolor.RecursiveColor(&c1)), @"");
}

- (void)testMaximums {
    MaxConstructorsT v = MaxConstructors.MaxParams19(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18);
    XCTAssertEqual(v.tag, MaxParams19, @"");

    XCTAssertEqual(v.C19P1, 0, @"");
    XCTAssertEqual(v.C19P19, 18, @"");
    XCTAssertTrue(MaxConstructorsEqualToMaxConstructors(v,
        MaxConstructors.MaxParams19(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18)), @"");
}

@end
