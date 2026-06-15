// FUN_005909f0  entry=005909f0  size=102 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_005909f0(int param_1,char param_2)

{
  int *piVar1;
  byte bVar2;
  int iVar3;
  byte bVar4;
  
  if (((DAT_006d31c4 == '\0') && (*(int *)(param_1 + 0x4c) == 0)) && (*(int *)(param_1 + 0x50) != 0)
     ) {
    iVar3 = *(int *)(*(int *)(param_1 + 0x50) + 0x3b8);
    if (param_2 == '\0') {
      piVar1 = (int *)(iVar3 + 0x80);
      *piVar1 = *piVar1 + 1;
    }
    else {
      piVar1 = (int *)(iVar3 + 0x7c);
      *piVar1 = *piVar1 + 1;
    }
    bVar2 = *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462);
    bVar4 = bVar2 & 0x40;
    if ((bVar4 != 0) || ((bVar2 & 0xa0) != 0)) {
      FUN_00594470((bVar4 != 0) + '\x15',*(undefined4 *)(param_1 + 0x50),0);
    }
  }
  return;
}


