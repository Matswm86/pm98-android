// FUN_0042c030  entry=0042c030  size=386 bytes

void __thiscall FUN_0042c030(void *this,byte *param_1,int param_2)

{
  undefined4 *puVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int local_30;
  int local_2c;
  undefined4 local_28;
  undefined4 local_24;
  int local_20;
  int local_1c;
  int local_18;
  int local_14;
  int local_10 [4];
  
  FUN_00462910(*(void **)((int)this + 0x3d4),&local_30,param_1);
  if (param_2 != 0) {
    local_20 = 0x29;
    local_30 = local_30 + 0x29;
    if (local_30 < 0x2a) {
      local_20 = local_30;
    }
    local_18 = 0x29;
    if (0x28 < local_30) {
      local_18 = local_30;
    }
    local_2c = local_2c + 10;
    local_1c = 10;
    if (local_2c < 0xb) {
      local_1c = local_2c;
    }
    local_14 = 10;
    if (9 < local_2c) {
      local_14 = local_2c;
    }
    FUN_00404230((void *)((int)this + 0x78),local_10,(void *)((int)this + 0x78));
    puVar1 = (undefined4 *)FUN_0041f4c0(&local_20,&local_30,local_10);
    *(undefined4 *)((int)this + 0x88) = *puVar1;
    *(undefined4 *)((int)this + 0x8c) = puVar1[1];
    *(undefined4 *)((int)this + 0x90) = puVar1[2];
    *(undefined4 *)((int)this + 0x94) = puVar1[3];
    return;
  }
  iVar4 = local_30 + 6;
  local_10[0] = 6;
  if (iVar4 < 7) {
    local_10[0] = iVar4;
  }
  iVar2 = 6;
  if (5 < iVar4) {
    iVar2 = iVar4;
  }
  iVar4 = local_2c + 2;
  iVar3 = 2;
  if (iVar4 < 3) {
    iVar3 = iVar4;
  }
  if (iVar4 < 2) {
    iVar4 = 2;
  }
  CRect::CRect((CRect *)&local_20,0,0,*(int *)((int)this + 0x80) - *(int *)((int)this + 0x78),
               *(int *)((int)this + 0x84) - *(int *)((int)this + 0x7c));
  if (local_14 <= iVar4) {
    iVar4 = local_14;
  }
  if (local_18 <= iVar2) {
    iVar2 = local_18;
  }
  if (local_1c < iVar3) {
    local_1c = iVar3;
  }
  if (local_20 < local_10[0]) {
    local_20 = local_10[0];
  }
  CRect::CRect((CRect *)&local_30,local_20,local_1c,iVar2,iVar4);
  *(int *)((int)this + 0x88) = local_30;
  *(int *)((int)this + 0x8c) = local_2c;
  *(undefined4 *)((int)this + 0x90) = local_28;
  *(undefined4 *)((int)this + 0x94) = local_24;
  return;
}


