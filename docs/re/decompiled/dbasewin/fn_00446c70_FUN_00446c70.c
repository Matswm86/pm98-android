// FUN_00446c70  entry=00446c70  size=126 bytes

uint __thiscall FUN_00446c70(void *this,int param_1)

{
  int *piVar1;
  char *pcVar2;
  uint uVar3;
  undefined4 uVar4;
  void *pvVar5;
  int iVar6;
  CRect local_10 [16];
  
  iVar6 = 0;
  pvVar5 = this;
  FUN_004042d0(&stack0xffffffe0,0xffffff);
  uVar4 = 0;
  uVar3 = 0x4000;
  pcVar2 = &DAT_00496cd0;
  piVar1 = (int *)CRect::CRect(local_10,0,0,0x280,0x1e0);
  uVar3 = FUN_0045d470(this,param_1,piVar1,pcVar2,uVar3,uVar4,pvVar5,iVar6);
  if (uVar3 != 0) {
    FUN_004565e0(this,&DAT_00496cd0);
    FUN_00448d90((void *)((int)this + 0x430),(int)this,0x29,3);
  }
  return uVar3;
}


