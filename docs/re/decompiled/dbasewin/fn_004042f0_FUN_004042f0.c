// FUN_004042f0  entry=004042f0  size=157 bytes

void __thiscall FUN_004042f0(void *this,undefined1 *param_1,byte *param_2,uint param_3)

{
  byte *pbVar1;
  uint uVar2;
  int iVar3;
  uint local_8;
  uint local_4;
  
  uVar2 = param_3;
  pbVar1 = param_2;
  local_8 = (uint)*(byte *)((int)this + 2);
  local_4 = (uint)param_2[2];
  param_3 = (uint)*(byte *)((int)this + 1);
  param_2 = (byte *)(uint)param_2[1];
  iVar3 = 0x100 - uVar2;
  *param_1 = (char)(*(byte *)this * uVar2 + iVar3 * (uint)*pbVar1 >> 8);
  param_1[1] = (char)(param_3 * uVar2 + (int)param_2 * iVar3 >> 8);
  param_1[3] = 0;
  param_1[2] = (char)(local_8 * uVar2 + local_4 * iVar3 >> 8);
  return;
}


