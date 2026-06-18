// FUN_005ee080  entry=005ee080  size=112 bytes

short FUN_005ee080(uint param_1,uint param_2)

{
  short sVar1;
  int iVar2;
  int iVar3;
  
  sVar1 = 0;
  if ((param_1 != 0) || (param_2 != 0)) {
    iVar3 = (param_1 ^ (int)param_1 >> 0x1f) - ((int)param_1 >> 0x1f);
    iVar2 = (param_2 ^ (int)param_2 >> 0x1f) - ((int)param_2 >> 0x1f);
    if (iVar3 < iVar2) {
      iVar2 = FUN_005edf90(iVar3,iVar2);
      sVar1 = 0x4000 - (&DAT_006d71c8)[iVar2 >> 3];
    }
    else {
      iVar2 = FUN_005edf90(iVar2,iVar3);
      sVar1 = (&DAT_006d71c8)[iVar2 >> 3];
    }
    if ((int)param_1 < 0) {
      sVar1 = -0x8000 - sVar1;
    }
    if ((int)param_2 < 0) {
      sVar1 = -sVar1;
    }
  }
  return sVar1;
}


