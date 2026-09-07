import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { notificationExtensionSubscription } from '@kit.NotificationKit';
import { BluetoothDevice } from '../models/BluetoothDevice';
import { BluetoothDeviceService } from '../services/BluetoothDeviceService';
import { NotificationSubscriptionService } from '../services/NotificationSubscriptionService';

const DOMAIN = 0x0000;
const TAG = 'HarmonyOtpBridge';

@Entry
@Component
struct Index {
  @State private grantStatus: string = '未检查';
  @State private bluetoothStatus: string = '未检查';
  @State private devices: BluetoothDevice[] = [];
  @State private selectedAddress: string = '';
  @State private selectedDeviceName: string = '';
  @State private subscriptionStatus: string = '未检查';
  @State private subscriptionAddress: string = '';
  @State private lastError: string = '';

  private bluetoothDeviceService: BluetoothDeviceService = new BluetoothDeviceService();
  private notificationSubscriptionService: NotificationSubscriptionService =
    new NotificationSubscriptionService();

  aboutToAppear(): void {
    this.refreshGrantStatus();
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Harmony Mac OTP Bridge')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)

        Text('Phase 0.2 · Notification Gate')
          .fontSize(16)
          .fontColor('#666666')

        Divider()

        Text(`通知权限：${this.grantStatus}`)
          .fontSize(18)

        Button('打开通知订阅授权')
          .width('100%')
          .onClick(() => {
            this.openSubscriptionSettings();
          })

        Button('检查通知权限')
          .width('100%')
          .onClick(() => {
            this.refreshGrantStatus();
          })

        Divider()

        Text(`蓝牙权限：${this.bluetoothStatus}`)
          .fontSize(18)

        Button('刷新蓝牙设备')
          .width('100%')
          .onClick(() => {
            this.loadBluetoothDevices();
          })

        Text('已配对设备')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)

        if (this.devices.length === 0) {
          Text('暂无设备，请先点击“刷新蓝牙设备”')
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
        } else {
          ForEach(this.devices, (device: BluetoothDevice) => {
            Row({ space: 12 }) {
              Text(this.selectedAddress === device.address ? '●' : '○')
                .fontSize(22)
                .fontColor(this.selectedAddress === device.address ? '#0A59F7' : '#666666')

              Column({ space: 4 }) {
                Text(device.name.length > 0 ? device.name : '未命名设备')
                  .fontSize(17)
                  .alignSelf(ItemAlign.Start)
                Text(device.address)
                  .fontSize(14)
                  .fontColor('#666666')
                  .alignSelf(ItemAlign.Start)
              }
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .borderRadius(8)
            .backgroundColor(this.selectedAddress === device.address ? '#EAF2FF' : '#F5F5F5')
            .onClick(() => {
              this.selectedAddress = device.address;
              this.selectedDeviceName = device.name;
              this.lastError = '';
            });
          }, (device: BluetoothDevice) => device.address)
        }

        Button('订阅选中设备')
          .width('100%')
          .onClick(() => {
            this.subscribeSelectedDevice();
          })

        Divider()

        Text('通知订阅状态')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)

        Text(`状态：${this.subscriptionStatus}`)
          .fontSize(17)
          .alignSelf(ItemAlign.Start)

        if (this.subscriptionAddress.length > 0) {
          Text(`目标设备：${this.getSubscriptionDeviceName()}`)
            .fontSize(16)
            .alignSelf(ItemAlign.Start)
          Text(this.subscriptionAddress)
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
        }

        Button('检查订阅状态')
          .width('100%')
          .onClick(() => {
            this.refreshSubscriptionInfo();
          })

        Button('取消订阅')
          .width('100%')
          .onClick(() => {
            this.unsubscribe();
          })

        if (this.lastError.length > 0) {
          Text(this.lastError)
            .fontSize(14)
            .fontColor('#D93025')
            .textAlign(TextAlign.Start)
            .alignSelf(ItemAlign.Start)
        }

        Text('收到通知后，请在 DevEco Studio Hilog 中搜索 [NOTIFICATION_RECEIVED]。')
          .fontSize(14)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding(24)
    }
    .width('100%')
    .height('100%')
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
      this.setBusinessError('打开通知授权页面失败', error as BusinessError);
    }
  }

  private async refreshGrantStatus(): Promise<void> {
    try {
      const isGranted = await notificationExtensionSubscription.isUserGranted();
      this.grantStatus = isGranted ? '已授权' : '未授权';
      hilog.info(DOMAIN, TAG, 'Notification subscription granted: %{public}s', String(isGranted));
    } catch (error) {
      this.setBusinessError('读取通知授权状态失败', error as BusinessError);
    }
  }

  private async loadBluetoothDevices(): Promise<void> {
    this.lastError = '';
    try {
      const granted = await this.bluetoothDeviceService.ensureBluetoothPermission(this.getAbilityContext());
      this.bluetoothStatus = granted ? '已授权' : '未授权';
      if (!granted) {
        return;
      }

      this.devices = this.bluetoothDeviceService.getPairedDevices();
      if (!this.devices.some((device: BluetoothDevice) => device.address === this.selectedAddress)) {
        this.selectedAddress = '';
        this.selectedDeviceName = '';
      }
    } catch (error) {
      this.bluetoothStatus = '读取失败';
      this.setError('读取已配对蓝牙设备失败', error as Error);
    }
  }

  private async subscribeSelectedDevice(): Promise<void> {
    this.lastError = '';
    if (this.selectedAddress.length === 0) {
      this.lastError = '请先选择一个蓝牙设备';
      return;
    }
    try {
      const notificationGranted = await notificationExtensionSubscription.isUserGranted();
      this.grantStatus = notificationGranted ? '已授权' : '未授权';
      if (!notificationGranted) {
        this.lastError = '请先完成通知订阅授权';
        return;
      }

      await this.notificationSubscriptionService.subscribe(this.selectedAddress);
      await this.refreshSubscriptionInfo();
    } catch (error) {
      this.subscriptionStatus = '订阅失败';
      this.setError('订阅通知失败', error as Error);
    }
  }

  private async refreshSubscriptionInfo(): Promise<void> {
    this.lastError = '';
    try {
      const info = await this.notificationSubscriptionService.getSubscriptionInfo();
      if (info.length === 0) {
        this.subscriptionStatus = '未订阅';
        this.subscriptionAddress = '';
        return;
      }

      this.subscriptionStatus = '已订阅';
      this.subscriptionAddress = info[0].addr;
      const target = this.devices.find((device: BluetoothDevice) => device.address === info[0].addr);
      this.selectedAddress = info[0].addr;
      this.selectedDeviceName = target?.name ?? '';
    } catch (error) {
      this.subscriptionStatus = '读取失败';
      this.setError('读取通知订阅状态失败', error as Error);
    }
  }

  private async unsubscribe(): Promise<void> {
    this.lastError = '';
    try {
      await this.notificationSubscriptionService.unsubscribe();
      this.subscriptionStatus = '未订阅';
      this.subscriptionAddress = '';
    } catch (error) {
      this.setError('取消通知订阅失败', error as Error);
    }
  }

  private getSubscriptionDeviceName(): string {
    if (this.selectedDeviceName.length > 0) {
      return this.selectedDeviceName;
    }
    const target = this.devices.find((device: BluetoothDevice) => device.address === this.subscriptionAddress);
    return target?.name ?? '未知设备';
  }

  private setError(prefix: string, error: Error): void {
    this.lastError = `${prefix}：${error.message}`;
    hilog.error(
      DOMAIN,
      TAG,
      '%{public}s message=%{public}s',
      prefix,
      error.message
    );
  }

  private setBusinessError(prefix: string, error: BusinessError): void {
    this.lastError = `${prefix}：${error.code} ${error.message}`;
    hilog.error(
      DOMAIN,
      TAG,
      '%{public}s code=%{public}d message=%{public}s',
      prefix,
      error.code,
      error.message
    );
  }
}
