import { hilog } from '@kit.PerformanceAnalysisKit';
import { notificationExtensionSubscription, NotificationSubscriberExtensionAbility } from '@kit.NotificationKit';

const DOMAIN = 0x0000;
const TAG = 'HarmonyOtpBridge';

export default class NotificationSubscriberExtAbility extends NotificationSubscriberExtensionAbility {
  onReceiveMessage(notificationInfo: notificationExtensionSubscription.NotificationInfo): void {
    hilog.info(DOMAIN, TAG, 'NotificationInfo received: %{public}s', JSON.stringify(notificationInfo));
  }

  onCancelMessages(hashCodes: Array<string>): void {
    hilog.info(DOMAIN, TAG, 'Notification cancelled: %{public}s', JSON.stringify(hashCodes));
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Notification subscriber destroyed');
  }
}

