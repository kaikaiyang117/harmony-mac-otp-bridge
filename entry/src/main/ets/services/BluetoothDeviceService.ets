import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { connection } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BluetoothDevice } from '../models/BluetoothDevice';

const DOMAIN = 0x0000;
const TAG = 'HarmonyOtpBridge';
const BLUETOOTH_PERMISSION = 'ohos.permission.ACCESS_BLUETOOTH';

export class BluetoothDeviceService {
  async ensureBluetoothPermission(context: common.UIAbilityContext): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const currentStatus = await atManager.checkAccessToken(
        context.applicationInfo.accessTokenId,
        BLUETOOTH_PERMISSION
      );
      if (currentStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        hilog.info(DOMAIN, TAG, 'Bluetooth permission already granted');
        return true;
      }

      const result = await atManager.requestPermissionsFromUser(context, [BLUETOOTH_PERMISSION]);
      const permissionIndex = result.permissions.indexOf(BLUETOOTH_PERMISSION);
      const granted = permissionIndex >= 0 &&
        result.authResults[permissionIndex] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      hilog.info(DOMAIN, TAG, 'Bluetooth permission request result: %{public}s', JSON.stringify(result));
      return granted;
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(
        DOMAIN,
        TAG,
        'ACCESS_BLUETOOTH failed code=%{public}d message=%{public}s',
        businessError.code,
        businessError.message
      );
      throw new Error(`code=${businessError.code} message=${businessError.message}`);
    }
  }

  getPairedDevices(): BluetoothDevice[] {
    try {
      const addresses = connection.getPairedDevices();
      const devices: BluetoothDevice[] = [];
      addresses.forEach((address: string) => {
        try {
          const name = connection.getRemoteDeviceName(address);
          devices.push({ address, name });
        } catch (error) {
          const businessError = error as BusinessError;
          hilog.error(
            DOMAIN,
            TAG,
            'getRemoteDeviceName failed address=%{public}s code=%{public}d message=%{public}s',
            address,
            businessError.code,
            businessError.message
          );
        }
      });
      hilog.info(DOMAIN, TAG, 'Paired Bluetooth devices: %{public}s', JSON.stringify(devices));
      return devices;
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(
        DOMAIN,
        TAG,
        'getPairedDevices failed code=%{public}d message=%{public}s',
        businessError.code,
        businessError.message
      );
      throw new Error(`code=${businessError.code} message=${businessError.message}`);
    }
  }
}
