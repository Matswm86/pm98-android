// FUN_0057a340  entry=0057a340  size=83 bytes

uint __fastcall FUN_0057a340(int param_1)

{
  int iVar1;
  uint uVar2;
  
  uVar2 = 0;
  if (*(int *)(param_1 + 0x28) != 0) {
    for (iVar1 = *(int *)(param_1 + 0x24); iVar1 != 0; iVar1 = *(int *)(iVar1 + 0x100)) {
      uVar2 = *(byte *)(iVar1 + 0x9d) + uVar2 +
              (uint)*(byte *)(iVar1 + 0x9e) + (uint)*(byte *)(iVar1 + 0x9f) +
              (uint)*(byte *)(iVar1 + 0x9c);
    }
    uVar2 = uVar2 / (uint)(*(int *)(param_1 + 0x28) * 4);
  }
  return uVar2;
}


