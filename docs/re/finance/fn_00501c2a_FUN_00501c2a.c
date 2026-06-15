// FUN_00501c2a  entry=00501c2a  size=1260 bytes

undefined4 FUN_00501c2a(void)

{
  int *piVar1;
  int iVar2;
  undefined4 *in_EAX;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined1 uVar5;
  int unaff_EBX;
  int unaff_ESI;
  int *unaff_EDI;
  float10 fVar6;
  undefined4 uStack0000000c;
  undefined4 uStack00000024;
  undefined1 *puVar7;
  char *pcVar8;
  undefined4 uVar9;
  
  *in_EAX = 0xffffffff;
  iVar2 = *unaff_EDI;
  FUN_00436270(0xffffffff);
  uVar3 = FUN_00436fb0(0xdd,0x32);
  uVar4 = FUN_00436fb0(8,0x19f);
  FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar2 + 0xc0))();
  FUN_005beae0(s_ProMan8_00658928);
  iVar2 = *(int *)(unaff_ESI + 0x192c) + -1;
  *(int *)(unaff_ESI + 0x32f8) = iVar2;
  if (*(int *)(unaff_ESI + 0x192c) == unaff_EBX) {
    *(int *)(unaff_ESI + 0x3698) = unaff_EBX;
    *(int *)(unaff_ESI + 0x369c) = unaff_EBX;
    *(int *)(unaff_ESI + 0x36a0) = unaff_EBX;
  }
  else {
    fVar6 = (float10)FUN_0057fce0(iVar2);
    *(float *)(unaff_ESI + 0x3698) = (float)fVar6;
    fVar6 = (float10)FUN_00580730(*(int *)(unaff_ESI + 0x192c) + -1);
    *(float *)(unaff_ESI + 0x369c) = (float)fVar6;
    fVar6 = (float10)FUN_00580750(*(int *)(unaff_ESI + 0x192c) + -1);
    *(float *)(unaff_ESI + 0x36a0) = (float)fVar6;
  }
  uVar5 = (undefined1)unaff_EBX;
  uStack00000024 = CONCAT13(uVar5,0x633c39);
  uVar3 = uStack00000024;
  uStack00000024 = CONCAT13(uVar5,0xf7cbce);
  uVar4 = uStack00000024;
  uStack00000024 = CONCAT13(uVar5,0xdeb6b5);
  *(undefined4 *)(unaff_ESI + 0x36a4) = uVar3;
  *(undefined4 *)(unaff_ESI + 0x36a8) = uVar4;
  *(undefined4 *)(unaff_ESI + 0x36ac) = uStack00000024;
  iVar2 = *(int *)(unaff_ESI + 14000);
  FUN_00436270(0xffffffff);
  uVar3 = FUN_00436fb0(0xdd,0x32);
  uVar4 = FUN_00436fb0(0xf1,0x19f);
  FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar2 + 0xc0))();
  FUN_005beae0(s_ProMan8_00658928);
  *(undefined4 *)(unaff_ESI + 0x3704) = *(undefined4 *)(unaff_ESI + 0x192c);
  fVar6 = (float10)FUN_0057fce0(*(undefined4 *)(unaff_ESI + 0x192c));
  *(float *)(unaff_ESI + 0x3aa4) = (float)fVar6;
  fVar6 = (float10)FUN_00580730(*(undefined4 *)(unaff_ESI + 0x192c));
  *(float *)(unaff_ESI + 0x3aa8) = (float)fVar6;
  fVar6 = (float10)FUN_00580750(*(undefined4 *)(unaff_ESI + 0x192c));
  *(float *)(unaff_ESI + 0x3aac) = (float)fVar6;
  uStack0000000c = CONCAT13(uVar5,0x633418);
  uVar3 = uStack0000000c;
  uStack0000000c = CONCAT13(uVar5,0xdecbb5);
  *(undefined4 *)(unaff_ESI + 0x3ab0) = uVar3;
  *(undefined4 *)(unaff_ESI + 0x3ab4) = uStack0000000c;
  uStack0000000c = CONCAT13(uVar5,0xceb6a5);
  *(undefined4 *)(unaff_ESI + 0x3ab8) = uStack0000000c;
  piVar1 = (int *)(unaff_ESI + 0x46c0);
  iVar2 = *piVar1;
  FUN_00436270(0xffffffff);
  uVar3 = FUN_00436fb0(0x250,0x1b);
  uVar4 = FUN_00436fb0(0x15,0x33);
  FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar2 + 0xc0))();
  FUN_005beae0(s_Proman10_00652e9c);
  iVar2 = *(int *)(unaff_ESI + 0x3abc);
  FUN_00437020(0x2a,0x3f,0xaa);
  uVar9 = 0x20;
  pcVar8 = s_INCOME___EXPENSES_006595e0;
  uVar3 = FUN_00436fb0(0xad,0xe);
  uVar4 = FUN_00436fb0(10,7);
  uVar3 = FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar2 + 0xc0))(piVar1,uVar3,pcVar8,uVar9);
  FUN_005beae0(s_ProMan10_006551e0);
  *(int *)(unaff_ESI + 0x3eb8) = unaff_EBX;
  iVar2 = *(int *)(unaff_ESI + 0x3ed8);
  FUN_00436270(0xffffffff);
  uVar3 = FUN_00436fb0(0x22,9);
  uVar4 = FUN_00436fb0(0x29,0x24);
  FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar2 + 0xc0))();
  FUN_005c06d0(s_recursos_iconos_caja_flechaRed_b_006595bc,unaff_EBX,0x10,0x32,unaff_EBX);
  iVar2 = *(int *)(unaff_ESI + 0x42cc);
  FUN_00436270(0xffffffff);
  uVar3 = FUN_00436fb0(0x22,9);
  uVar4 = FUN_00436fb0(0x19b,0x24);
  FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar2 + 0xc0))();
  FUN_005c06d0(s_recursos_iconos_caja_flechaGreen_00659594,unaff_EBX,0x10,0x32,unaff_EBX);
  iVar2 = *(int *)(unaff_ESI + 0x4ab4);
  FUN_00436270(unaff_EBX);
  uVar3 = FUN_00436fb0(0x10,0x10);
  uVar4 = FUN_00436fb0(0x107,6);
  uVar3 = FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar2 + 0xc0))(piVar1,uVar3);
  FUN_005c06d0(s_recursos_iconos_caja_flechal_bmp_00659570,unaff_EBX,unaff_EBX,0x32,unaff_EBX);
  *(undefined2 *)(unaff_ESI + 0x4e42) = 0x80;
  *(short *)(unaff_ESI + 0x4e44) = (short)unaff_EBX;
  iVar2 = *(int *)(unaff_ESI + 0x4ecc);
  FUN_00436270(unaff_EBX);
  uVar9 = 0xc9;
  puVar7 = &DAT_00666f70;
  uVar3 = FUN_00436fb0(0x10,0x10);
  uVar4 = FUN_00436fb0(0x174,6);
  uVar3 = FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar2 + 0xc0))(piVar1,uVar3,puVar7);
  FUN_005c06d0(s_Mrecursos_iconos_caja_flechar_bm_0065954b + 1,unaff_EBX,unaff_EBX,0x32,unaff_EBX);
  *(undefined2 *)(unaff_ESI + 0x525a) = 0x80;
  *(short *)(unaff_ESI + 0x525c) = (short)unaff_EBX;
  FUN_00502120();
  return uVar9;
}


