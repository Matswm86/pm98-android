// FUN_0044ed40  entry=0044ed40  size=276 bytes

undefined4 __thiscall
FUN_0044ed40(void *this,int param_1,int param_2,int param_3,int param_4,uint param_5)

{
  bool bVar1;
  int *piVar2;
  undefined4 uVar3;
  int iVar4;
  undefined4 *puVar5;
  undefined4 local_64;
  undefined4 local_60;
  undefined4 local_5c [18];
  uint local_14;
  
  local_64 = 100;
  local_60 = 0;
  puVar5 = local_5c;
  for (iVar4 = 0x17; iVar4 != 0; iVar4 = iVar4 + -1) {
    *puVar5 = 0;
    puVar5 = puVar5 + 1;
  }
  if (*(int *)((int)this + 0x20) == 8) {
    local_14 = param_5;
  }
  else {
    local_14 = (uint)*(ushort *)
                      (*(int *)(&DAT_00495820 + *(int *)((int)this + 0x20) * 4) + param_5 * 2);
  }
  param_1 = param_1 + *(int *)((int)this + 0x38);
  param_2 = param_2 + *(int *)((int)this + 0x3c);
  param_4 = param_4 + *(int *)((int)this + 0x3c);
  param_3 = param_3 + *(int *)((int)this + 0x38);
  piVar2 = (int *)FUN_0044f980(&param_1,(int *)((int)this + 0x28));
  if ((*piVar2 < piVar2[2]) && (piVar2[1] < piVar2[3])) {
    bVar1 = true;
  }
  else {
    bVar1 = false;
  }
  if (bVar1) {
    if (((*(int *)this == 0) && (*(int *)((int)this + 0x40) == 0)) ||
       (uVar3 = FUN_0044e8b0(this), (char)uVar3 != '\0')) {
      bVar1 = true;
    }
    else {
      bVar1 = false;
    }
    if ((bVar1) &&
       (iVar4 = (**(code **)(**(int **)((int)this + 4) + 0x14))
                          (*(int **)((int)this + 4),&param_1,0,&param_1,0x1000400,&local_64),
       -1 < iVar4)) {
      return 1;
    }
    return 0;
  }
  return 1;
}


