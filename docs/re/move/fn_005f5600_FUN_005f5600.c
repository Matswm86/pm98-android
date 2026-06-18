// FUN_005f5600  entry=005f5600  size=147 bytes

bool __thiscall FUN_005f5600(int *param_1,int param_2)

{
  int iVar1;
  MMRESULT MVar2;
  UINT uJoyID;
  
  if (*param_1 != 0) goto LAB_005f5685;
  iVar1 = param_1[2];
  if (iVar1 == param_2) goto LAB_005f5685;
  if (iVar1 == 2) {
    uJoyID = 0;
LAB_005f5622:
    joyReleaseCapture(uJoyID);
  }
  else if (iVar1 == 3) {
    uJoyID = 1;
    goto LAB_005f5622;
  }
  param_1[2] = param_2;
  param_1[0x18] = 0;
  param_1[0x19] = 0;
  if (param_2 == 2) {
    MVar2 = joySetCapture((HWND)param_1[1],0,0,1);
    if (MVar2 != 0) {
      *param_1 = 1;
    }
  }
  else if (param_2 == 3) {
    MVar2 = joySetCapture((HWND)param_1[1],1,0,1);
    if (MVar2 != 0) {
      *param_1 = 1;
      return *param_1 == 0;
    }
  }
LAB_005f5685:
  return *param_1 == 0;
}


