import { NotificationContent } from '../models/NotificationContent';
import { OtpResult } from '../models/OtpResult';

const OTP_KEYWORDS: string[] = [
  '验证码',
  '校验码',
  '动态码',
  '动态密码',
  '验证代码',
  '确认码',
  'otp',
  'verification code',
  'verify code',
  'security code',
  'authentication code'
];

const DIRECT_KEYWORDS: string[] = [
  '验证码为',
  '验证码：',
  '验证码:',
  '验证码 ',
  '校验码为',
  '校验码：',
  '校验码:',
  'otp:',
  'otp：',
  'verification code is',
  'verification code:'
];

export class OtpParser {
  parse(content: NotificationContent): OtpResult | null {
    const title = content.title.trim();
    const text = content.text.trim();
    const combined = title.length > 0 ? `${title} ${text}` : text;
    const lowerCombined = combined.toLowerCase();

    if (!this.containsKeyword(lowerCombined)) {
      return null;
    }

    const directCode = this.findDirectCode(combined, lowerCombined);
    if (directCode.length > 0) {
      return {
        code: directCode,
        source: this.resolveSource(title, text)
      };
    }

    const nearbyCode = this.findNearbyCode(combined, lowerCombined);
    if (nearbyCode.length > 0) {
      return {
        code: nearbyCode,
        source: this.resolveSource(title, text)
      };
    }

    const allCodes = this.findAllCodes(combined);
    if (allCodes.length === 1) {
      return {
        code: allCodes[0],
        source: this.resolveSource(title, text)
      };
    }

    return null;
  }

  private containsKeyword(lowerText: string): boolean {
    for (const keyword of OTP_KEYWORDS) {
      if (lowerText.indexOf(keyword) >= 0) {
        return true;
      }
    }
    return false;
  }

  private findDirectCode(text: string, lowerText: string): string {
    for (const keyword of DIRECT_KEYWORDS) {
      let searchStart = lowerText.indexOf(keyword.toLowerCase());
      while (searchStart >= 0) {
        const code = this.findCodeInRange(text, searchStart + keyword.length, text.length);
        if (code.length > 0) {
          return code;
        }
        searchStart = lowerText.indexOf(keyword.toLowerCase(), searchStart + 1);
      }
    }
    return '';
  }

  private findNearbyCode(text: string, lowerText: string): string {
    for (const keyword of OTP_KEYWORDS) {
      let searchStart = lowerText.indexOf(keyword);
      while (searchStart >= 0) {
        const rangeStart = Math.max(0, searchStart - 30);
        const rangeEnd = Math.min(text.length, searchStart + keyword.length + 30);
        const code = this.findCodeInRange(text, rangeStart, rangeEnd);
        if (code.length > 0) {
          return code;
        }
        searchStart = lowerText.indexOf(keyword, searchStart + 1);
      }
    }
    return '';
  }

  private findAllCodes(text: string): string[] {
    const codes: string[] = [];
    let index = 0;
    while (index < text.length) {
      if (!this.isDigit(text[index])) {
        index++;
        continue;
      }

      const start = index;
      while (index < text.length && this.isDigit(text[index])) {
        index++;
      }
      const code = text.substring(start, index);
      if (code.length >= 4 && code.length <= 8 && this.isStandaloneNumber(text, start, index) &&
        !this.isNonOtpNumber(text, start)) {
        codes.push(code);
      }
    }
    return codes;
  }

  private findCodeInRange(text: string, start: number, end: number): string {
    let index = start;
    while (index < end) {
      if (!this.isDigit(text[index])) {
        index++;
        continue;
      }

      const numberStart = index;
      while (index < end && this.isDigit(text[index])) {
        index++;
      }
      const code = text.substring(numberStart, index);
      if (code.length >= 4 && code.length <= 8 && this.isStandaloneNumber(text, numberStart, index) &&
        !this.isNonOtpNumber(text, numberStart)) {
        return code;
      }
    }
    return '';
  }

  private isStandaloneNumber(text: string, start: number, end: number): boolean {
    const before = start > 0 ? text[start - 1] : '';
    const after = end < text.length ? text[end] : '';
    return !this.isDigit(before) && !this.isDigit(after);
  }

  private isNonOtpNumber(text: string, start: number): boolean {
    const contextStart = Math.max(0, start - 8);
    const prefix = text.substring(contextStart, start);
    const excludedPrefixes: string[] = [
      '订单号',
      '单号',
      '快递',
      '尾号',
      '金额',
      '余额',
      '价格',
      '编号'
    ];
    for (const excludedPrefix of excludedPrefixes) {
      if (prefix.indexOf(excludedPrefix) >= 0) {
        return true;
      }
    }
    return false;
  }

  private isDigit(value: string): boolean {
    return value >= '0' && value <= '9';
  }

  private resolveSource(title: string, text: string): string {
    if (title.length > 0) {
      return title;
    }

    const start = text.indexOf('【');
    const end = text.indexOf('】', start + 1);
    if (start >= 0 && end > start + 1) {
      return text.substring(start + 1, end);
    }
    return '验证码';
  }
}
