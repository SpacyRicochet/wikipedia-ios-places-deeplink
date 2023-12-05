#import "WKSourceEditorFormatterBoldItalics.h"
#import "WKSourceEditorColors.h"
#import "WKSourceEditorFonts.h"

@interface WKSourceEditorFormatterBoldItalics ()

@property (nonatomic, strong) NSDictionary *boldItalicsAttributes;
@property (nonatomic, strong) NSDictionary *boldAttributes;
@property (nonatomic, strong) NSDictionary *italicsAttributes;
@property (nonatomic, strong) NSDictionary *orangeAttributes;

@property (nonatomic, strong) NSRegularExpression *boldItalicsRegex;
@property (nonatomic, strong) NSRegularExpression *boldRegex;
@property (nonatomic, strong) NSRegularExpression *italicsRegex;

@end

@implementation WKSourceEditorFormatterBoldItalics

#pragma mark - Custom Attributed String Keys

// Font and Color custom attributes allow us to easily target already-formatted ranges. This is handy for speedy updates upon theme and text size change, as well as determining keyboard button selection states.
NSString * const WKSourceEditorCustomKeyColorOrange = @"WKSourceEditorKeyColorOrange";
NSString * const WKSourceEditorCustomKeyFontBoldItalics = @"WKSourceEditorKeyFontBoldItalics";
NSString * const WKSourceEditorCustomKeyFontBold = @"WKSourceEditorKeyFontBold";
NSString * const WKSourceEditorCustomKeyFontItalics = @"WKSourceEditorKeyFontItalics";

- (instancetype)initWithColors:(WKSourceEditorColors *)colors fonts:(WKSourceEditorFonts *)fonts {
    self = [super initWithColors:colors fonts:fonts];
    if (self) {
        _orangeAttributes = @{
            NSForegroundColorAttributeName: colors.orangeForegroundColor,
            WKSourceEditorCustomKeyColorOrange: [NSNumber numberWithBool:YES]
        };
        
        _boldItalicsAttributes = @{
            NSFontAttributeName: fonts.boldItalicsFont,
            WKSourceEditorCustomKeyFontBoldItalics: [NSNumber numberWithBool:YES]
        };
        
        _boldAttributes = @{
            NSFontAttributeName: fonts.boldFont,
            WKSourceEditorCustomKeyFontBold: [NSNumber numberWithBool:YES]
        };
        
        _italicsAttributes = @{
            NSFontAttributeName: fonts.italicsFont,
            WKSourceEditorCustomKeyFontItalics: [NSNumber numberWithBool:YES]
        };
        
        _boldItalicsRegex = [[NSRegularExpression alloc] initWithPattern:@"('{5})(.*?)('{5})" options:0 error:nil];
        _boldRegex = [[NSRegularExpression alloc] initWithPattern:@"('{3})(.*?)('{3})" options:0 error:nil];
        _italicsRegex = [[NSRegularExpression alloc] initWithPattern:@"((?<!')'{2}(?!'))(.*?)((?<!')'{2}(?!'))" options:0 error:nil];
    }
    return self;
}

- (void)addSyntaxHighlightingToAttributedString:(nonnull NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    // Reset
    [attributedString removeAttribute:WKSourceEditorCustomKeyColorOrange range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontBoldItalics range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontBold range:range];
    [attributedString removeAttribute:WKSourceEditorCustomKeyFontItalics range:range];
    
    NSMutableArray *boldItalicsRanges = [[NSMutableArray alloc] init];
    NSMutableArray *boldOnlyRanges = [[NSMutableArray alloc] init];
    
    [self.boldItalicsRegex enumerateMatchesInString:attributedString.string
                                       options:0
                                         range:range
                                    usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                        NSRange fullMatch = [result rangeAtIndex:0];
                                        NSRange openingRange = [result rangeAtIndex:1];
                                        NSRange textRange = [result rangeAtIndex:2];
                                        NSRange closingRange = [result rangeAtIndex:3];

                                        if (fullMatch.location != NSNotFound) {
                                            [boldItalicsRanges addObject:[NSValue valueWithRange:fullMatch]];
                                        }
        
                                        if (openingRange.location != NSNotFound) {
                                            [attributedString addAttributes:self.orangeAttributes range:openingRange];
                                        }

                                        if (textRange.location != NSNotFound) {
                                            [attributedString addAttributes:self.boldItalicsAttributes range:textRange];
                                        }

                                        if (closingRange.location != NSNotFound) {
                                            [attributedString addAttributes:self.orangeAttributes range:closingRange];
                                        }
                                    }];
    
    [self.boldRegex enumerateMatchesInString:attributedString.string
                                       options:0
                                         range:range
                                    usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                        NSRange fullMatch = [result rangeAtIndex:0];
                                        NSRange openingRange = [result rangeAtIndex:1];
                                        NSRange textRange = [result rangeAtIndex:2];
                                        NSRange closingRange = [result rangeAtIndex:3];
    
                                        BOOL alreadyBoldAndItalic = NO;
                                        for (NSValue *value in boldItalicsRanges) {
                                            NSRange boldItalicRange = value.rangeValue;
                                            if (NSIntersectionRange(boldItalicRange, fullMatch).length != 0) {
                                                alreadyBoldAndItalic = YES;
                                            }
                                        }

                                        if (alreadyBoldAndItalic) {
                                            return;
                                        }
        
                                        if (fullMatch.location != NSNotFound) {
                                            [boldOnlyRanges addObject:[NSValue valueWithRange:fullMatch]];
                                        }
        
                                        if (openingRange.location != NSNotFound) {
                                            [attributedString addAttributes:self.orangeAttributes range:openingRange];
                                        }

                                        if (textRange.location != NSNotFound) {
                                            [attributedString addAttributes:self.boldAttributes range:textRange];
                                        }

                                        if (closingRange.location != NSNotFound) {
                                            [attributedString addAttributes:self.orangeAttributes range:closingRange];
                                        }
                                    }];
    
    [self.italicsRegex enumerateMatchesInString:attributedString.string
                                       options:0
                                         range:range
                                    usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                        NSRange fullMatch = [result rangeAtIndex:0];
                                        NSRange openingRange = [result rangeAtIndex:1];
                                        NSRange textRange = [result rangeAtIndex:2];
                                        NSRange closingRange = [result rangeAtIndex:3];
        
                                        BOOL alreadyBoldAndItalic = NO;
                                        for (NSValue *value in boldItalicsRanges) {
                                            NSRange boldItalicRange = value.rangeValue;
                                            if (NSIntersectionRange(boldItalicRange, fullMatch).length != 0) {
                                                alreadyBoldAndItalic = YES;
                                            }
                                        }
        
                                        if (alreadyBoldAndItalic) {
                                            return;
                                        }
        
                                        if (openingRange.location != NSNotFound) {
                                            [attributedString addAttributes:self.orangeAttributes range:openingRange];
                                        }

                                        if (textRange.location != NSNotFound) {
                                            
                                            // Italicize match
                                            [attributedString addAttributes:self.italicsAttributes range:textRange];
                                            
                                            // Dig deeper to see if some areas need bold italic font instead. In this case previous line effects will be undone.
                                            for (NSValue *value in boldOnlyRanges) {
                                                NSRange boldRange = value.rangeValue;
                                                
                                                NSRange intersectionRange = NSIntersectionRange(boldRange, fullMatch);
                                                BOOL boldSurroundsItalic = intersectionRange.length > 0 && boldRange.location < fullMatch.location && boldRange.length > fullMatch.length;
                                                BOOL italicSurroundsBold = intersectionRange.length > 0 && fullMatch.location < boldRange.location && fullMatch.length > boldRange.length;
                                                
                                                if (boldSurroundsItalic) {
                                                    
                                                    // Reset range styling to prep for bold italic
                                                    [attributedString removeAttribute:NSFontAttributeName range:textRange];
                                                    [attributedString removeAttribute:WKSourceEditorCustomKeyFontItalics range:textRange];
                                                    [attributedString removeAttribute:WKSourceEditorCustomKeyFontBold range:intersectionRange];
                                                    
                                                    // Bold italicize instead
                                                    [attributedString addAttributes:self.boldItalicsAttributes range:textRange];
                                                    
                                                } else if (italicSurroundsBold) {
                                                    
                                                    // Reset range styling to prep for bold italic
                                                    [attributedString removeAttribute:NSFontAttributeName range:intersectionRange];
                                                    [attributedString removeAttribute:WKSourceEditorCustomKeyFontItalics range:intersectionRange];
                                                    [attributedString removeAttribute:WKSourceEditorCustomKeyFontBold range:intersectionRange];
                                                    
                                                    // Bold italicize instead
                                                    [attributedString addAttributes:self.boldItalicsAttributes range:intersectionRange];
                                                }
                                            }
                                        }

                                        if (closingRange.location != NSNotFound) {
                                            [attributedString addAttributes:self.orangeAttributes range:closingRange];
                                        }
                                    }];
}

- (void)updateColors:(WKSourceEditorColors *)colors inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    // First update orangeAttributes property so that addSyntaxHighlighting has the correct color the next time it is called
    NSMutableDictionary *mutAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.orangeAttributes];
    [mutAttributes setObject:colors.orangeForegroundColor forKey:NSForegroundColorAttributeName];
    self.orangeAttributes = [[NSDictionary alloc] initWithDictionary:mutAttributes];
    
    // Then update entire attributed string orange color
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyColorOrange
                     inRange:range
                     options:nil
                  usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.orangeAttributes range:localRange];
            }
        }
    }];
}

- (void)updateFonts:(WKSourceEditorFonts *)fonts inAttributedString:(NSMutableAttributedString *)attributedString inRange:(NSRange)range {
    
    // First update font attributes properties so that addSyntaxHighlighting has the correct fonts the next time it is called
    NSMutableDictionary *mutBoldItalicsAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.boldItalicsAttributes];
    [mutBoldItalicsAttributes setObject:fonts.boldItalicsFont forKey:NSFontAttributeName];
    self.boldItalicsAttributes = [[NSDictionary alloc] initWithDictionary:mutBoldItalicsAttributes];
    
    NSMutableDictionary *mutBoldAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.boldAttributes];
    [mutBoldAttributes setObject:fonts.boldFont forKey:NSFontAttributeName];
    self.boldAttributes = [[NSDictionary alloc] initWithDictionary:mutBoldAttributes];
    
    NSMutableDictionary *mutItalicsAttributes = [[NSMutableDictionary alloc] initWithDictionary:self.italicsAttributes];
    [mutItalicsAttributes setObject:fonts.italicsFont forKey:NSFontAttributeName];
    self.italicsAttributes = [[NSDictionary alloc] initWithDictionary:mutItalicsAttributes];
    
    // Then update entire attributed string fonts
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyFontBoldItalics
                     inRange:range
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.boldItalicsAttributes range:localRange];
            }
        }
    }];

    [attributedString enumerateAttribute:WKSourceEditorCustomKeyFontBold
                     inRange:range
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.boldAttributes range:localRange];
            }
        }
    }];
    
    [attributedString enumerateAttribute:WKSourceEditorCustomKeyFontItalics
                     inRange:range
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange localRange, BOOL *stop) {
        if ([value isKindOfClass: [NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue boolValue] == YES) {
                [attributedString addAttributes:self.italicsAttributes range:localRange];
            }
        }
    }];
}

- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isBoldInRange:(NSRange)range {
    __block BOOL isBold = NO;
    if (range.length == 0) {
        
        if (attributedString.length > range.location) {
            NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];
            
            if (attrs[WKSourceEditorCustomKeyFontBoldItalics] != nil || attrs[WKSourceEditorCustomKeyFontBold] != nil) {
                isBold = YES;
            }
        }
        
    } else {
        [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
                if ((attrs[WKSourceEditorCustomKeyFontBoldItalics] != nil || attrs[WKSourceEditorCustomKeyFontBold] != nil) &&
                    (loopRange.location == range.location && loopRange.length == range.length)) {
                    isBold = YES;
                    stop = YES;
                }
        }];
    }
    
    
    return isBold;
}
- (BOOL)attributedString:(NSMutableAttributedString *)attributedString isItalicsInRange:(NSRange)range {
    __block BOOL isItalics = NO;
    
    if (range.length == 0) {
        
        if (attributedString.length > range.location) {
            NSDictionary<NSAttributedStringKey,id> *attrs = [attributedString attributesAtIndex:range.location effectiveRange:nil];
            
            if (attrs[WKSourceEditorCustomKeyFontBoldItalics] != nil || attrs[WKSourceEditorCustomKeyFontItalics] != nil) {
                isItalics = YES;
            }
        }
        
    } else {
        [attributedString enumerateAttributesInRange:range options:nil usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange loopRange, BOOL * _Nonnull stop) {
                if ((attrs[WKSourceEditorCustomKeyFontBoldItalics] != nil || attrs[WKSourceEditorCustomKeyFontItalics] != nil) &&
                    (loopRange.location == range.location && loopRange.length == range.length)) {
                    isItalics = YES;
                    stop = YES;
                }
        }];
    }
    
    return isItalics;
}

@end
