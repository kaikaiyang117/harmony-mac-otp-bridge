import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { notificationExtensionSubscription } from '@kit.NotificationKit';

const DOMAIN = 0x0000;
const TAG = 'HarmonyOtpBridge';

export class NotificationSubscriptionService {
  async subscribe(bluetoothAddress: string): Promise<void> {
    const subscriptionInfo: notificationExtensionSubscription.NotificationExtensionSubscriptionInfo[] = [
      {
        addr: bluetoothAddress,
        type: notificationExtensionSubscription.SubscribeType.BLUETOOTH
      }
    ];

    try {
      await notificationExtensionSubscription.subscribe(subscriptionInfo);
      hilog.info(DOMAIN, TAG, 'Subscription succeeded: %{public}s', JSON.stringify(subscriptionInfo));
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(
        DOMAIN,
        TAG,
        'subscribe failed code=%{public}d message=%{public}s',
        businessError.code,
        businessError.message
      );
      throw new Error(`code=${businessError.code} message=${businessError.message}`);
    }
  }

  async unsubscribe(): Promise<void> {
    try {
      await notificationExtensionSubscription.unsubscribe();
      hilog.info(DOMAIN, TAG, 'Unsubscription succeeded');
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(
        DOMAIN,
        TAG,
        'unsubscribe failed code=%{public}d message=%{public}s',
        businessError.code,
        businessError.message
      );
      throw new Error(`code=${businessError.code} message=${businessError.message}`);
    }
  }

  async getSubscriptionInfo(): Promise<notificationExtensionSubscription.NotificationExtensionSubscriptionInfo[]> {
    try {
      const info = await notificationExtensionSubscription.getSubscribeInfo();
      hilog.info(DOMAIN, TAG, 'Subscription info: %{public}s', JSON.stringify(info));
      return info;
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(
        DOMAIN,
        TAG,
        'getSubscribeInfo failed code=%{public}d message=%{public}s',
        businessError.code,
        businessError.message
      );
      throw new Error(`code=${businessError.code} message=${businessError.message}`);
    }
  }
}
