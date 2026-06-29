// FUN_0042b3e0  entry=0042b3e0  size=325 bytes

void __thiscall FUN_0042b3e0(void *this,uint param_1)

{
  int *this_00;
  int iVar1;
  void *pvVar2;
  int iVar3;
  undefined4 uVar4;
  int *piVar5;
  int *piVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  undefined4 uStack_15c;
  undefined1 local_140 [8];
  undefined1 local_138 [28];
  char acStack_11c [12];
  undefined1 local_110 [272];
  
  uStack_15c = 0x42b3fe;
  pvVar2 = (void *)FUN_00445a90(&DAT_00497e10,param_1);
  iVar3 = FUN_0043b680(pvVar2);
  iVar3 = *(int *)(iVar3 + 0x2c);
  this_00 = (int *)((int)this + 0x3dc4);
  iVar1 = *this_00;
  FUN_004042d0(&uStack_15c,0);
  uVar9 = 0xdc;
  uVar8 = 0x200808;
  uVar4 = FUN_0042b530(iVar3);
  piVar5 = (int *)FUN_00404120(local_138,0x13c,0x1a);
  piVar6 = (int *)FUN_00404120(local_140,3,0x14);
  uVar7 = FUN_00404180(local_110,piVar6,piVar5);
  (**(code **)(iVar1 + 0xc0))((void *)((int)this + 0x5654),uVar7,uVar4,uVar8,uVar9);
  FUN_00456560(this_00,s_Futuri18_00493b24);
  FUN_00404b20(this_00,0xbfd4);
  if (1 < *(uint *)((int)this + 0x2d60)) {
    FUN_00457340(this_00,0,'\x01');
  }
  if (*(int *)(iVar3 + 0x34) == 0) {
    FUN_00457340(this_00,0,'\x01');
  }
  FUN_004457d0(*(undefined4 *)(iVar3 + 8),&stack0xfffffeb4);
  sprintf(acStack_11c,s__s_s_bmp_00492428,s_DBDAT_MINIENTR__00493b14,&stack0xfffffeb4);
  iVar3 = FUN_004014e0(acStack_11c);
  if (iVar3 != 0) {
    FUN_004580b0((void *)((int)this + 0x5654),acStack_11c,0,0,0x32,0);
  }
  return;
}


