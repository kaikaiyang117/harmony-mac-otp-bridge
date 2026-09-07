import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { notificationExtensionSubscription } from '@kit.NotificationKit';

const DOMAIN = 0x0000;
const TAG = 'HarmonyOtpBridge';

@Entry
@Component
struct Index {
  @State private grantStatus: string = '未检查';
  @State private lastError: string = '';

  build() {
    Column({ space: 20 }) {
      Text('Harmony Mac OTP Bridge')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)

      Text('Phase 0.1 · API 22 通知订阅 Gate')
        .fontSize(16)
        .fontColor('#666666')

      Divider()

      Text(`通知订阅授权：${this.grantStatus}`)
        .fontSize(18)

      Button('打开通知订阅授权')
        .width('100%')
        .onClick(() => {
          this.openSubscriptionSettings();
        })

      Button('检查授权状态')
        .width('100%')
        .onClick(() => {
          this.refreshGrantStatus();
        })

      if (this.lastError.length > 0) {
        Text(this.lastError)
          .fontSize(14)
          .fontColor('#D93025')
      }

      Text('收到通知后，请在 DevEco Studio 日志中搜索 HarmonyOtpBridge。')
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private async openSubscriptionSettings(): Promise<void> {
    this.lastError = '';
    try {
      await notificationExtensionSubscription.openSubscriptionSettings(this.getAbilityContext());
      hilog.info(DOMAIN, TAG, 'Notification subscription settings closed');
      await this.refreshGrantStatus();
    } catch (error) {
      const businessError = error as BusinessError;
      this.lastError = `打开授权页面失败：${businessError.code} ${businessError.message}`;
      hilog.error(DOMAIN, TAG, 'Failed to open subscription settings: %{public}s', JSON.stringify(businessError));
    }
  }

  private async refreshGrantStatus(): Promise<void> {
    this.lastError = '';
    try {
      const isGranted = await notificationExtensionSubscription.isUserGranted();
      this.grantStatus = isGranted ? '已授权' : '未授权';
      hilog.info(DOMAIN, TAG, 'Notification subscription granted: %{public}s', String(isGranted));
    } catch (error) {
      const businessError = error as BusinessError;
      this.lastError = `读取授权状态失败：${businessError.code} ${businessError.message}`;
      hilog.error(DOMAIN, TAG, 'Failed to read subscription status: %{public}s', JSON.stringify(businessError));
    }
  }
}

