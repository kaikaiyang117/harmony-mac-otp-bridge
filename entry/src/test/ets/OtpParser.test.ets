import { describe, expect, it } from '@ohos/hypium';
import { NotificationContent } from '../../main/ets/models/NotificationContent';
import { OtpParser } from '../../main/ets/services/OtpParser';

function content(text: string, title: string = ''): NotificationContent {
  return {
    packageName: 'test.bundle',
    title,
    text
  };
}

export default function OtpParserTest(): void {
  describe('OtpParser', () => {
    const parser = new OtpParser();

    it('extracts Chinese code with keyword', 0, () => {
      expect(parser.parse(content('【牛客】您的验证码为381926，5分钟内有效'))?.code).assertEqual('381926');
    });

    it('extracts four digit code', 0, () => {
      expect(parser.parse(content('您的验证码：1234'))?.code).assertEqual('1234');
    });

    it('extracts OTP code', 0, () => {
      expect(parser.parse(content('OTP: 847291'))?.code).assertEqual('847291');
    });

    it('extracts English verification code', 0, () => {
      expect(parser.parse(content('Your verification code is 720134'))?.code).assertEqual('720134');
    });

    it('rejects order number without keyword', 0, () => {
      expect(parser.parse(content('订单号 381926'))).assertNull();
    });

    it('rejects shipment number without keyword', 0, () => {
      expect(parser.parse(content('您的订单381926已发货'))).assertNull();
    });

    it('rejects unrelated time number', 0, () => {
      expect(parser.parse(content('验证码将在5分钟内发送'))).assertNull();
    });

    it('extracts code adjacent to keyword', 0, () => {
      expect(parser.parse(content('验证码381926，有效期5分钟'))?.code).assertEqual('381926');
    });

    it('rejects multiple unrelated numbers', 0, () => {
      expect(parser.parse(content('验证码将在5分钟内发送，订单号为123456'))).assertNull();
    });

    it('uses title as source', 0, () => {
      expect(parser.parse(content('您的验证码为381926', '牛客'))?.source).assertEqual('牛客');
    });

    it('uses bracket source when title is empty', 0, () => {
      expect(parser.parse(content('【BOSS直聘】验证码为381926'))?.source).assertEqual('BOSS直聘');
    });
  });
}
