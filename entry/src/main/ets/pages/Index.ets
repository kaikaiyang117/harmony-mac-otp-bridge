import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { notificationExtensionSubscription } from '@kit.NotificationKit';
import { BarkConfig } from '../models/BarkConfig';
import { BluetoothDevice } from '../models/BluetoothDevice';
import { BarkPushService } from '../services/BarkPushService';
import { BluetoothDeviceService } from '../services/BluetoothDeviceService';
import { ConfigService } from '../services/ConfigService';
import { NotificationSubscriptionService } from '../services/NotificationSubscriptionService';

const DOMAIN = 0x0000;
const TAG = 'HarmonyOtpBridge';

@Entry
@Component
struct Index {
  @State private grantStatus: string = '检查中';
  @State private devices: BluetoothDevice[] = [];
  @State private selectedAddress: string = '';
  @State private subscriptionStatus: string = '检查中';
  @State private showDeviceSetup: boolean = false;
  @State private serverUrl: string = '';
  @State private deviceKey: string = '';
  @State private forwardingEnabled: boolean = true;
  @State private barkStatus: string = '检查中';
  @State private showBarkConfig: boolean = true;
  @State private lastError: string = '';

  private bluetoothDeviceService: BluetoothDeviceService = new BluetoothDeviceService();
  private notificationSubscriptionService: NotificationSubscriptionService =
    new NotificationSubscriptionService();
  private configService: ConfigService = new ConfigService();
  private barkPushService: BarkPushService = new BarkPushService();

  aboutToAppear(): void {
    this.refreshGrantStatus();
    this.refreshSubscriptionInfo();
    this.loadBarkConfig();
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Column({ space: 4 }) {
          Text('验证码转发')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#171A1F')
            .alignSelf(ItemAlign.Start)

          Text('HarmonyOS → BarkMac')
            .fontSize(15)
            .fontColor('#68707D')
            .alignSelf(ItemAlign.Start)
        }
        .width('100%')

        Column({ space: 12 }) {
          Row({ space: 16 }) {
            Column({ space: 4 }) {
              Text(this.getOverallTitle())
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isReady() ? '#176B3A' : '#171A1F')
                .alignSelf(ItemAlign.Start)

              Text(this.getOverallDescription())
                .fontSize(14)
                .fontColor('#68707D')
                .alignSelf(ItemAlign.Start)
            }
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.forwardingEnabled })
              .selectedColor('#0A59F7')
              .onChange((isOn: boolean) => {
                this.forwardingEnabled = isOn;
                this.saveBarkConfig();
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor(this.isReady() ? '#EAF7EF' : '#FFFFFF')
        .borderRadius(16)

        Column({ space: 14 }) {
          Text('通知接入')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#171A1F')
            .alignSelf(ItemAlign.Start)

          Row() {
            Text('通知权限')
              .fontSize(16)
              .fontColor('#2C313A')
              .layoutWeight(1)
            Text(this.grantStatus)
              .fontSize(15)
              .fontColor(this.grantStatus === '已授权' ? '#176B3A' : '#68707D')
          }
          .width('100%')

          Row() {
            Text('设备订阅')
              .fontSize(16)
              .fontColor('#2C313A')
              .layoutWeight(1)
            Text(this.subscriptionStatus)
              .fontSize(15)
              .fontColor(this.subscriptionStatus === '已订阅' ? '#176B3A' : '#68707D')
          }
          .width('100%')

          if (this.grantStatus !== '已授权') {
            Button('允许读取通知')
              .width('100%')
              .height(48)
              .fontSize(16)
              .backgroundColor('#0A59F7')
              .borderRadius(12)
              .onClick(() => {
                this.openSubscriptionSettings();
              })
          }

          if (this.grantStatus === '已授权' && this.subscriptionStatus !== '已订阅' &&
            !this.showDeviceSetup) {
            Button('选择订阅设备')
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor('#0A59F7')
              .backgroundColor('#EEF3FF')
              .borderRadius(12)
              .onClick(() => {
                this.prepareSubscriptionSetup();
              })
          }

          if (this.showDeviceSetup) {
            Text('选择一台已配对设备，用于激活系统通知订阅。')
              .fontSize(14)
              .fontColor('#68707D')
              .alignSelf(ItemAlign.Start)

            if (this.devices.length === 0) {
              Text('未找到已配对设备，请先在系统蓝牙设置中完成配对。')
                .fontSize(14)
                .fontColor('#68707D')
                .alignSelf(ItemAlign.Start)
            } else {
              ForEach(this.devices, (device: BluetoothDevice) => {
                Row({ space: 12 }) {
                  Stack() {
                    Row()
                      .width(20)
                      .height(20)
                      .borderRadius(10)
                      .border({
                        width: 1,
                        color: this.selectedAddress === device.address ? '#0A59F7' : '#A9B0BB'
                      })
                    if (this.selectedAddress === device.address) {
                      Row()
                        .width(10)
                        .height(10)
                        .borderRadius(5)
                        .backgroundColor('#0A59F7')
                    }
                  }

                  Text(device.name.length > 0 ? device.name : '未命名设备')
                    .fontSize(16)
                    .fontColor('#2C313A')
                    .layoutWeight(1)
                }
                .width('100%')
                .padding(14)
                .backgroundColor(this.selectedAddress === device.address ? '#EEF3FF' : '#F5F6F8')
                .borderRadius(12)
                .onClick(() => {
                  this.selectedAddress = device.address;
                  this.lastError = '';
                })
              }, (device: BluetoothDevice) => device.address)
            }

            Button('完成订阅')
              .width('100%')
              .height(48)
              .fontSize(16)
              .enabled(this.selectedAddress.length > 0)
              .backgroundColor(this.selectedAddress.length > 0 ? '#0A59F7' : '#C8CDD5')
              .borderRadius(12)
              .onClick(() => {
                this.subscribeSelectedDevice();
              })
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        Column({ space: 14 }) {
          Row() {
            Text('BarkMac')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#171A1F')
              .layoutWeight(1)
            Text(this.barkStatus)
              .fontSize(15)
              .fontColor(this.isBarkConfigured() ? '#176B3A' : '#68707D')
          }
          .width('100%')

          if (this.showBarkConfig) {
            Text('服务地址')
              .fontSize(14)
              .fontColor('#2C313A')
              .alignSelf(ItemAlign.Start)

            TextInput({ placeholder: 'http://192.168.x.x:8080', text: this.serverUrl })
              .width('100%')
              .height(48)
              .backgroundColor('#F5F6F8')
              .borderRadius(10)
              .onChange((value: string) => {
                this.serverUrl = value;
              })

            Text('Device Key')
              .fontSize(14)
              .fontColor('#2C313A')
              .alignSelf(ItemAlign.Start)

            TextInput({ placeholder: '从 BarkMac 复制', text: this.deviceKey })
              .width('100%')
              .height(48)
              .type(InputType.Password)
              .showPasswordIcon(false)
              .backgroundColor('#F5F6F8')
              .borderRadius(10)
              .onChange((value: string) => {
                this.deviceKey = value;
              })

            Button('保存并测试')
              .width('100%')
              .height(48)
              .fontSize(16)
              .backgroundColor('#0A59F7')
              .borderRadius(12)
              .onClick(() => {
                this.saveAndTestBarkConfig();
              })
          } else {
            Text(this.serverUrl)
              .fontSize(14)
              .fontColor('#68707D')
              .maxLines(1)
              .alignSelf(ItemAlign.Start)

            Button('修改 Bark 配置')
              .width('100%')
              .height(44)
              .fontSize(15)
              .fontColor('#0A59F7')
              .backgroundColor('#EEF3FF')
              .borderRadius(12)
              .onClick(() => {
                this.showBarkConfig = true;
                this.barkStatus = '待保存';
              })
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        if (this.lastError.length > 0) {
          Text(this.lastError)
            .width('100%')
            .padding(14)
            .fontSize(14)
            .fontColor('#A3271C')
            .backgroundColor('#FFF1F0')
            .borderRadius(12)
            .textAlign(TextAlign.Start)
        }

        Text('验证码只在手机本地提取；配置和日志不会保存验证码内容。')
          .fontSize(13)
          .fontColor('#7C8490')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 28, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F5F7')
  }

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private getCurrentConfig(): BarkConfig {
    return {
      serverUrl: this.serverUrl,
      deviceKey: this.deviceKey,
      enabled: this.forwardingEnabled
    };
  }

  private isBarkConfigured(): boolean {
    return this.configService.isValid(this.getCurrentConfig());
  }

  private isReady(): boolean {
    return this.forwardingEnabled && this.grantStatus === '已授权' &&
      this.subscriptionStatus === '已订阅' && this.isBarkConfigured();
  }

  private getOverallTitle(): string {
    if (!this.forwardingEnabled) {
      return '转发已暂停';
    }
    return this.isReady() ? '正在转发' : '需要完成设置';
  }

  private getOverallDescription(): string {
    if (!this.forwardingEnabled) {
      return '打开开关即可恢复验证码转发';
    }
    return this.isReady() ? '验证码通知会自动发送到这台 Mac' : '完成下方缺失项目后即可使用';
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
      this.grantStatus = '读取失败';
      this.setBusinessError('读取通知授权状态失败', error as BusinessError);
    }
  }

  private async loadBarkConfig(): Promise<void> {
    try {
      const config = await this.configService.loadBarkConfig(this.getAbilityContext());
      this.serverUrl = config.serverUrl;
      this.deviceKey = config.deviceKey;
      this.forwardingEnabled = config.enabled;
      const configured = this.configService.isValid(config);
      this.barkStatus = configured ? '已配置' : '未配置';
      this.showBarkConfig = !configured;
    } catch (error) {
      this.barkStatus = '读取失败';
      this.setError('读取 Bark 配置失败', error as Error);
    }
  }

  private async saveBarkConfig(): Promise<boolean> {
    this.lastError = '';
    const config = this.getCurrentConfig();
    try {
      await this.configService.saveBarkConfig(this.getAbilityContext(), config);
      this.serverUrl = this.configService.normalizeServerUrl(this.serverUrl);
      this.barkStatus = this.configService.isValid(config) ? '已配置' : '配置不完整';
      return true;
    } catch (error) {
      this.barkStatus = '保存失败';
      this.setError('保存 Bark 配置失败', error as Error);
      return false;
    }
  }

  private async saveAndTestBarkConfig(): Promise<void> {
    const config = this.getCurrentConfig();
    if (!this.configService.isValid(config)) {
      this.barkStatus = '配置不完整';
      this.lastError = '请填写有效的服务地址和 Device Key';
      return;
    }

    if (!await this.saveBarkConfig()) {
      return;
    }

    this.barkStatus = '正在测试';
    try {
      await this.barkPushService.push(this.getCurrentConfig(), {
        title: 'Harmony OTP Test',
        body: 'Bark connection works',
        group: 'OTP'
      });
      this.barkStatus = '连接正常';
      this.showBarkConfig = false;
    } catch (error) {
      this.barkStatus = '连接失败';
      this.setError('Bark 连接测试失败', error as Error);
    }
  }

  private async prepareSubscriptionSetup(): Promise<void> {
    this.showDeviceSetup = true;
    await this.loadBluetoothDevices();
  }

  private async loadBluetoothDevices(): Promise<void> {
    this.lastError = '';
    try {
      const granted = await this.bluetoothDeviceService.ensureBluetoothPermission(this.getAbilityContext());
      if (!granted) {
        this.lastError = '需要蓝牙权限才能选择通知订阅设备';
        return;
      }

      this.devices = this.bluetoothDeviceService.getPairedDevices();
      if (!this.devices.some((device: BluetoothDevice) => device.address === this.selectedAddress)) {
        this.selectedAddress = '';
      }
    } catch (error) {
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
      this.showDeviceSetup = false;
    } catch (error) {
      this.subscriptionStatus = '订阅失败';
      this.setError('订阅通知失败', error as Error);
    }
  }

  private async refreshSubscriptionInfo(): Promise<void> {
    try {
      const info = await this.notificationSubscriptionService.getSubscriptionInfo();
      if (info.length === 0) {
        this.subscriptionStatus = '未订阅';
        this.selectedAddress = '';
        return;
      }

      this.subscriptionStatus = '已订阅';
      this.selectedAddress = info[0].addr;
    } catch (error) {
      this.subscriptionStatus = '读取失败';
      this.setError('读取通知订阅状态失败', error as Error);
    }
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
