// FUN_004d0b57  entry=004d0b57  size=1133 bytes

undefined4 FUN_004d0b57(void)

{
  int iVar1;
  int iVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 *puVar5;
  int iVar6;
  int unaff_EBX;
  int unaff_ESI;
  int unaff_EDI;
  int iStack_50;
  char *pcStack_4c;
  char *pcStack_48;
  int iStack_40;
  char *pcStack_3c;
  int iStack_38;
  int iStack_34;
  undefined4 uStack_30;
  char *pcStack_2c;
  
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  iVar2 = (**(code **)(unaff_EBX + 0xc0))();
  if (iVar2 == 0) {
    return 0;
  }
  FUN_005beae0();
  *(undefined1 *)(unaff_ESI + 0x4e9) = 0x20;
  *(uint *)(unaff_EDI + 0xac) = *(uint *)(unaff_EDI + 0xac) | 8;
  iVar2 = *(int *)(unaff_ESI + 0x1d40);
  if (DAT_0066b1e4 == 0) {
    FUN_00436270();
    pcStack_2c = (char *)0x4d0c01;
    FUN_00436fb0();
    pcStack_2c = (char *)0x1a;
    uStack_30 = 0x4d0c0f;
    FUN_00436fb0();
  }
  else {
    FUN_00436270();
    pcStack_2c = (char *)0x4d0c34;
    FUN_00436fb0();
    pcStack_2c = (char *)0x1a;
    uStack_30 = 0x4d0c42;
    FUN_00436fb0();
  }
  pcStack_2c = (char *)0x4d0c4c;
  FUN_00436fd0();
  pcStack_2c = (char *)0x4d0c56;
  (**(code **)(iVar2 + 0xc0))();
  pcStack_2c = s_ProMan10_006551e0;
  uStack_30 = 0x4d0c62;
  FUN_005beae0();
  *(undefined1 *)(unaff_ESI + 0x1da5) = 0x30;
  *(undefined4 *)(unaff_ESI + 0x213c) = 0;
  pcStack_2c = (char *)0xffffffff;
  iVar2 = *(int *)(unaff_ESI + 0x2158);
  iStack_34 = 0xffffff;
  iStack_38 = 0x4d0c92;
  FUN_00436270();
  iStack_34 = 0x6d;
  iStack_38 = 0x820;
  pcStack_3c = s_League_0065672c;
  iStack_40 = 0x12;
  pcStack_48 = (char *)0x4d0cab;
  iStack_40 = FUN_00436fb0();
  pcStack_48 = (char *)0x28;
  pcStack_4c = (char *)0x4d0cb9;
  FUN_00436fb0();
  pcStack_48 = (char *)0x4d0cc3;
  iStack_40 = FUN_00436fd0();
  pcStack_48 = (char *)0x4d0ccd;
  (**(code **)(iVar2 + 0xc0))();
  pcStack_48 = s_ProMan10_006551e0;
  pcStack_4c = (char *)0x4d0cd9;
  FUN_005beae0();
  *(undefined1 *)(unaff_ESI + 0x21bd) = 0x30;
  iStack_50 = 0;
  *(undefined4 *)(unaff_ESI + 0x2554) = 0;
  pcStack_48 = (char *)0xc8a0a0;
  iVar2 = *(int *)(unaff_ESI + 0x1928);
  FUN_00437020(0xff,0xff);
  iStack_50 = 1;
  uVar3 = FUN_00436fb0(0x70,0x19);
  uVar4 = FUN_00436fb0(0x208,0x1af);
  FUN_00436fd0(uVar4,uVar3);
  iVar2 = (**(code **)(iVar2 + 0xc0))();
  if (iVar2 == 0) {
    return 0;
  }
  iVar2 = FUN_0043c920(unaff_ESI,0xb,0xa8,0x202,0xad,0x80,5);
  if (iVar2 != 0) {
    uVar4 = 5;
    uVar3 = 0x80;
    puVar5 = (undefined4 *)CRect::CRect((CRect *)&uStack_30,0x1fd,0x40,0x202,0xad);
    FUN_0043c920(unaff_ESI,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar3,uVar4);
  }
  uVar4 = 5;
  uVar3 = 0x80;
  puVar5 = (undefined4 *)CRect::CRect((CRect *)&uStack_30,0xb,0x102,0x202,0x107);
  iVar2 = FUN_0043c920(unaff_ESI,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar3,uVar4);
  if (iVar2 != 0) {
    uVar4 = 5;
    uVar3 = 0x80;
    puVar5 = (undefined4 *)CRect::CRect((CRect *)&uStack_30,0x1fd,0xab,0x202,0x107);
    FUN_0043c920(unaff_ESI,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar3,uVar4);
  }
  CRect::CRect((CRect *)&iStack_40,0xb,0x105,0x1fd,0x16a);
  iVar1 = iStack_34;
  iVar2 = iStack_38;
  pcStack_4c = pcStack_3c;
  uVar4 = 5;
  uVar3 = 0x80;
  iStack_50 = iStack_40;
  puVar5 = (undefined4 *)
           CRect::CRect((CRect *)&uStack_30,iStack_40,iStack_34,iStack_38 + 5,iStack_34 + 5);
  iVar6 = FUN_0043c920(unaff_ESI,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar3,uVar4);
  if (iVar6 != 0) {
    uVar4 = 5;
    uVar3 = 0x80;
    puVar5 = (undefined4 *)
             CRect::CRect((CRect *)&uStack_30,iVar2,(int)pcStack_4c,iVar2 + 5,iVar1 + 5);
    FUN_0043c920(unaff_ESI,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar3,uVar4);
  }
  uVar4 = 5;
  uVar3 = 0x80;
  iStack_50 = 0;
  pcStack_4c = (char *)0xa;
  iStack_40 = 0xb;
  iStack_38 = 0x1fd;
  pcStack_3c = (char *)0x177;
  iStack_34 = 0x1dc;
  puVar5 = (undefined4 *)FUN_00437be0(&uStack_30,&iStack_50);
  FUN_004d09b0(unaff_ESI,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar3,uVar4);
  return 1;
}


