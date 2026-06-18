// FUN_005eec60  entry=005eec60  size=333 bytes

int __thiscall FUN_005eec60(int *param_1,int *param_2,int *param_3,int *param_4,int param_5)

{
  int iVar1;
  longlong lVar2;
  longlong lVar3;
  bool bVar4;
  uint uVar5;
  int iVar6;
  int iVar7;
  int local_8;
  
  local_8 = 0;
  do {
    if (param_5 == 0) {
      return local_8;
    }
    lVar2 = (longlong)param_3[1] * (longlong)param_1[3] + (longlong)*param_3 * (longlong)*param_1 +
            (longlong)param_3[2] * (longlong)param_1[6];
    uVar5 = ((uint)lVar2 >> 0x10 | (int)((ulonglong)lVar2 >> 0x20) << 0x10) + param_1[9];
    lVar2 = (longlong)param_3[1] * (longlong)param_1[4] + (longlong)*param_3 * (longlong)param_1[1]
            + (longlong)param_3[2] * (longlong)param_1[7];
    iVar6 = param_1[10];
    lVar3 = (longlong)param_3[1] * (longlong)param_1[5] + (longlong)*param_3 * (longlong)param_1[2]
            + (longlong)param_3[2] * (longlong)param_1[8];
    iVar1 = param_1[0xb];
    *param_4 = *param_2;
    param_4[1] = param_2[1];
    if ((uVar5 & 0xffffff00) == 0) {
      iVar7 = -1;
    }
    else {
      iVar7 = -((int)uVar5 >> 8);
    }
    iVar6 = *param_4 +
            (int)(((uint)lVar2 >> 0x10 | (int)((ulonglong)lVar2 >> 0x20) << 0x10) + iVar6) / iVar7;
    *param_4 = iVar6;
    param_4[1] = param_4[1] +
                 (int)(((uint)lVar3 >> 0x10 | (int)((ulonglong)lVar3 >> 0x20) << 0x10) + iVar1) /
                 iVar7;
    if ((int)uVar5 < 0x8001) {
LAB_005eed82:
      local_8 = local_8 + 1;
    }
    else {
      if ((iVar6 < 0x2000) && (param_4[1] < 0x2000)) {
        bVar4 = true;
      }
      else {
        bVar4 = false;
      }
      if (!bVar4) goto LAB_005eed82;
      if ((iVar6 < -0x1fff) || (param_4[1] < -0x1fff)) {
        bVar4 = false;
      }
      else {
        bVar4 = true;
      }
      if (!bVar4) goto LAB_005eed82;
    }
    param_3 = param_3 + 3;
    param_4 = param_4 + 2;
    param_5 = param_5 + -1;
  } while( true );
}


