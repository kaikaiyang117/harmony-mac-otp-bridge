import { hilog } from '@kit.PerformanceAnalysisKit';
import { notificationExtensionSubscription, NotificationSubscriberExtensionAbility } from '@kit.NotificationKit';
import { NotificationExtractor } from '../services/NotificationExtractor';
import { OtpParser } from '../services/OtpParser';
import { BarkPushService } from '../services/BarkPushService';
import { ConfigService } from '../services/ConfigService';

const DOMAIN = 0x0000;
const TAG = 'HarmonyOtpBridge';
const DEDUPLICATION_WINDOW_MS = 60 * 1000;

export default class NotificationSubscriberExtAbility extends NotificationSubscriberExtensionAbility {
  private notificationExtractor: NotificationExtractor = new NotificationExtractor();
  private otpParser: OtpParser = new OtpParser();
  private barkPushService: BarkPushService = new BarkPushService();
  private configService: ConfigService = new ConfigService();
  private lastOtpKey: string = '';
  private lastOtpTimestamp: number = 0;

  onReceiveMessage(notificationInfo: notificationExtensionSubscription.NotificationInfo): void {
    this.handleNotification(notificationInfo).catch((error: Error) => {
      hilog.error(DOMAIN, TAG, 'Notification handling failed: %{public}s', error.message);
    });
  }

  onCancelMessages(hashCodes: Array<string>): void {
    hilog.info(DOMAIN, TAG, 'Notification cancelled: %{public}s', JSON.stringify(hashCodes));
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Notification subscriber destroyed');
  }

  private async handleNotification(
    notificationInfo: notificationExtensionSubscription.NotificationInfo
  ): Promise<void> {
    const content = this.notificationExtractor.extract(notificationInfo);
    hilog.info(
      DOMAIN,
      TAG,
      '[NOTIFICATION_RECEIVED] source=%{public}s bundle=%{public}s',
      content.title,
      content.packageName
    );

    const config = await this.configService.loadBarkConfig(this.context);
    if (!config.enabled) {
      hilog.info(DOMAIN, TAG, '[OTP_IGNORED] forwarding_disabled');
      return;
    }

    const otp = this.otpParser.parse(content);
    if (otp === null) {
      hilog.info(DOMAIN, TAG, '[OTP_IGNORED] source=%{public}s', content.title);
      return;
    }

    if (this.isDuplicate(otp.source, otp.code)) {
      hilog.info(DOMAIN, TAG, '[OTP_IGNORED] duplicate source=%{public}s', otp.source);
      return;
    }

    hilog.info(
      DOMAIN,
      TAG,
      '[OTP_DETECTED] source=%{public}s length=%{public}d',
      otp.source,
      otp.code.length
    );
    await this.barkPushService.push(config, {
      title: `${otp.source}验证码`,
      body: otp.code,
      group: 'OTP'
    });
  }

  private isDuplicate(source: string, code: string): boolean {
    const now = Date.now();
    const key = `${source}\u0000${code}`;
    const duplicate = key === this.lastOtpKey && now - this.lastOtpTimestamp < DEDUPLICATION_WINDOW_MS;
    this.lastOtpKey = key;
    this.lastOtpTimestamp = now;
    return duplicate;
  }
}
