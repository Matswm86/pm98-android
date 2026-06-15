// FUN_0050812e  entry=0050812e  size=2742 bytes

void __fastcall FUN_0050812e(undefined4 *param_1,undefined4 param_2)

{
  undefined4 in_EAX;
  int iVar1;
  undefined4 uVar2;
  int unaff_EBX;
  int unaff_ESI;
  uint uVar3;
  undefined4 *puVar4;
  float10 fVar5;
  undefined4 *in_stack_00000024;
  undefined4 in_stack_00000028;
  undefined4 in_stack_0000002c;
  undefined4 in_stack_00000030;
  float in_stack_00000034;
  undefined4 in_stack_00000040;
  float in_stack_00000044;
  float in_stack_0000004c;
  float in_stack_00000050;
  float in_stack_00000054;
  float in_stack_00000058;
  float in_stack_0000005c;
  float in_stack_00000060;
  float in_stack_00000064;
  float in_stack_00000068;
  float in_stack_0000006c;
  float in_stack_00000070;
  float in_stack_00000074;
  float in_stack_00000078;
  float in_stack_0000007c;
  float in_stack_00000080;
  float in_stack_00000084;
  float in_stack_00000088;
  float in_stack_0000008c;
  float in_stack_00000090;
  int in_stack_00000094;
  undefined4 in_stack_00000098;
  undefined4 in_stack_0000009c;
  undefined4 in_stack_000000a0;
  char *pcVar6;
  
  *param_1 = param_2;
  param_1[1] = in_EAX;
  param_1[2] = in_stack_00000040;
  param_1[3] = in_stack_00000044;
  FUN_005da180(s_TELEVISION_0065977c);
  iVar1 = (**(code **)(*DAT_0066b1b4 + 0x48))();
  if (iVar1 == 0) {
    iVar1 = (**(code **)(*DAT_0066b1b0 + 0x48))();
    if (iVar1 == 0) {
      CRect::CRect((CRect *)&stack0x00000024,DAT_0066b9b0 + 2,DAT_0066b9b4,DAT_0066b9b8 + 2,
                   DAT_0066b9bc);
      if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) != 0) {
        FUN_005da180(s_U_E_F_A__CUP_INCOME_00659ae0,in_stack_00000024);
        goto LAB_00508385;
      }
      pcVar6 = s_U_E_F_A__CUP_INCOME_00659ae0;
    }
    else {
      CRect::CRect((CRect *)&stack0x00000024,DAT_0066b9b0 + 2,DAT_0066b9b4,DAT_0066b9b8 + 2,
                   DAT_0066b9bc);
      if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) != 0) {
        FUN_005da180(&DAT_00659af4,in_stack_00000024);
        goto LAB_00508385;
      }
      pcVar6 = &DAT_00659af4;
    }
  }
  else {
    CRect::CRect((CRect *)&stack0x00000024,DAT_0066b9b0 + 2,DAT_0066b9b4,DAT_0066b9b8 + 2,
                 DAT_0066b9bc);
    if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) != 0) {
      FUN_005da180(s_EUROPEAN_CUP_INCOME_00659b0c,in_stack_00000024);
      goto LAB_00508385;
    }
    pcVar6 = s_EUROPEAN_CUP_INCOME_00659b0c;
  }
  FUN_005d9d80(pcVar6);
LAB_00508385:
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066b9c0 + 2,DAT_0066b9c4,DAT_0066b9c8 + 2,DAT_0066b9cc
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_SALE___LOAN_PLAY__00659acc);
  }
  else {
    FUN_005da180(s_SALE___LOAN_PLAY__00659acc,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066b9d0 + 2,DAT_0066b9d4,DAT_0066b9d8 + 2,DAT_0066b9dc
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_INSURANCE_GROUP_3_00659ab8);
  }
  else {
    FUN_005da180(s_INSURANCE_GROUP_3_00659ab8,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066b9e0 + 2,DAT_0066b9e4,DAT_0066b9e8 + 2,DAT_0066b9ec
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_LOANS_006597ac);
  }
  else {
    FUN_005da180(s_LOANS_006597ac,in_stack_00000024);
  }
  FUN_005d9d30();
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066b9f0 + 2,DAT_0066b9f4,DAT_0066b9f8 + 2,DAT_0066b9fc
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_SIGN_PLAYER_00659aac);
  }
  else {
    FUN_005da180(s_SIGN_PLAYER_00659aac,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066ba00 + 2,DAT_0066ba04,DAT_0066ba08 + 2,DAT_0066ba0c
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_CANCELLATION_00659a9c);
  }
  else {
    FUN_005da180(s_CANCELLATION_00659a9c,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066ba10 + 2,DAT_0066ba14,DAT_0066ba18 + 2,DAT_0066ba1c
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_00659a3c);
  }
  else {
    FUN_005da180(&DAT_00659a3c,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066ba20 + 2,DAT_0066ba24,DAT_0066ba28 + 2,DAT_0066ba2c
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_00659a2c);
  }
  else {
    FUN_005da180(&DAT_00659a2c,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066ba30 + 2,DAT_0066ba34,DAT_0066ba38 + 2,DAT_0066ba3c
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_00659a18);
  }
  else {
    FUN_005da180(&DAT_00659a18,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066ba40 + 2,DAT_0066ba44,DAT_0066ba48 + 2,DAT_0066ba4c
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_00659a04);
  }
  else {
    FUN_005da180(&DAT_00659a04,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066ba50 + 2,DAT_0066ba54,DAT_0066ba58 + 2,DAT_0066ba5c
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_HOSPITALS_006599f8);
  }
  else {
    FUN_005da180(s_HOSPITALS_006599f8,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066ba60 + 2,DAT_0066ba64,DAT_0066ba68 + 2,DAT_0066ba6c
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_STAFF_WAGES_006599ec);
  }
  else {
    FUN_005da180(s_STAFF_WAGES_006599ec,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066ba70 + 2,DAT_0066ba74,DAT_0066ba78 + 2,DAT_0066ba7c
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_REFORM_GROUND_00659a8c);
  }
  else {
    FUN_005da180(s_REFORM_GROUND_00659a8c,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066ba80 + 2,DAT_0066ba84,DAT_0066ba88 + 2,DAT_0066ba8c
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_FINES_006599d0);
  }
  else {
    FUN_005da180(s_FINES_006599d0,in_stack_00000024);
  }
  CRect::CRect((CRect *)&stack0x00000024,DAT_0066ba90 + 2,DAT_0066ba94,DAT_0066ba98 + 2,DAT_0066ba9c
              );
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_LOANS_AND_INTEREST_00659a78);
  }
  else {
    FUN_005da180(s_LOANS_AND_INTEREST_00659a78,in_stack_00000024);
  }
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) & 0xffffffdf;
  if (*(int *)(in_stack_00000094 + 0x1928) == unaff_EBX) {
    in_stack_00000034 = 0.0;
    puVar4 = &stack0x0000004c;
    for (iVar1 = 0x12; iVar1 != 0; iVar1 = iVar1 + -1) {
      *puVar4 = 0;
      puVar4 = puVar4 + 1;
    }
    in_stack_00000044 = 0.0;
    uVar3 = 0;
    do {
      fVar5 = (float10)FUN_005804d0();
      in_stack_0000004c = (float)(fVar5 + (float10)in_stack_0000004c);
      fVar5 = (float10)FUN_005806a0();
      in_stack_00000024 = (undefined4 *)(float)fVar5;
      fVar5 = (float10)FUN_00580660();
      in_stack_00000024 = (undefined4 *)(float)(fVar5 + (float10)(float)in_stack_00000024);
      fVar5 = (float10)FUN_00580540();
      in_stack_00000050 =
           (float)(fVar5 + (float10)(float)in_stack_00000024 + (float10)in_stack_00000050);
      fVar5 = (float10)FUN_00580610();
      in_stack_00000054 = (float)(fVar5 + (float10)in_stack_00000054);
      fVar5 = (float10)FUN_005806e0();
      in_stack_00000058 = (float)(fVar5 + (float10)in_stack_00000058);
      fVar5 = (float10)FUN_0057fee0();
      in_stack_0000005c = (float)(fVar5 + (float10)in_stack_0000005c);
      fVar5 = (float10)FUN_00580000();
      in_stack_00000060 = (float)(fVar5 + (float10)in_stack_00000060);
      fVar5 = (float10)FUN_0057fe00();
      in_stack_00000064 = (float)(fVar5 + (float10)in_stack_00000064);
      fVar5 = (float10)FUN_0057fea0();
      in_stack_00000068 = (float)(fVar5 + (float10)in_stack_00000068);
      fVar5 = (float10)FUN_0057fec0();
      in_stack_0000006c = (float)(fVar5 + (float10)in_stack_0000006c);
      fVar5 = (float10)FUN_0057ff00();
      in_stack_00000024 = (undefined4 *)(float)fVar5;
      fVar5 = (float10)FUN_0057ff20();
      in_stack_00000070 =
           (float)(((float10)(float)in_stack_00000024 - fVar5) + (float10)in_stack_00000070);
      fVar5 = (float10)FUN_0057ff40();
      in_stack_00000074 = (float)(fVar5 + (float10)in_stack_00000074);
      fVar5 = (float10)FUN_0057ff60();
      in_stack_00000078 = (float)(fVar5 + (float10)in_stack_00000078);
      fVar5 = (float10)FUN_0057ff80();
      in_stack_0000007c = (float)(fVar5 + (float10)in_stack_0000007c);
      fVar5 = (float10)FUN_0057ffa0();
      in_stack_00000024 = (undefined4 *)(float)fVar5;
      fVar5 = (float10)FUN_0057ffc0();
      in_stack_00000024 = (undefined4 *)(float)((float10)(float)in_stack_00000024 - fVar5);
      fVar5 = (float10)FUN_0057ffe0();
      in_stack_00000080 =
           (float)(((float10)(float)in_stack_00000024 - fVar5) + (float10)in_stack_00000080);
      fVar5 = (float10)FUN_00580020();
      in_stack_00000084 = (float)(fVar5 + (float10)in_stack_00000084);
      fVar5 = (float10)FUN_005800c0();
      in_stack_00000088 = (float)(fVar5 + (float10)in_stack_00000088);
      fVar5 = (float10)FUN_005800f0();
      in_stack_0000008c = (float)(fVar5 + (float10)in_stack_0000008c);
      fVar5 = (float10)FUN_0057fd60();
      in_stack_00000090 = (float)(fVar5 + (float10)in_stack_00000090);
      fVar5 = (float10)FUN_00580730();
      in_stack_00000034 = (float)(fVar5 + (float10)in_stack_00000034);
      fVar5 = (float10)FUN_00580750();
      uVar3 = uVar3 + 1;
      in_stack_00000044 = (float)(fVar5 + (float10)in_stack_00000044);
    } while (uVar3 < 0x34);
  }
  else {
    fVar5 = (float10)FUN_005804d0();
    in_stack_0000004c = (float)fVar5;
    fVar5 = (float10)FUN_005806a0();
    in_stack_00000024 = (undefined4 *)(float)fVar5;
    fVar5 = (float10)FUN_00580660();
    in_stack_00000024 = (undefined4 *)(float)(fVar5 + (float10)(float)in_stack_00000024);
    fVar5 = (float10)FUN_00580540();
    in_stack_00000050 = (float)(fVar5 + (float10)(float)in_stack_00000024);
    fVar5 = (float10)FUN_00580610();
    in_stack_00000054 = (float)fVar5;
    fVar5 = (float10)FUN_005806e0();
    in_stack_00000058 = (float)fVar5;
    fVar5 = (float10)FUN_0057fee0();
    in_stack_0000005c = (float)fVar5;
    fVar5 = (float10)FUN_00580000();
    in_stack_00000060 = (float)fVar5;
    fVar5 = (float10)FUN_0057fe00();
    in_stack_00000064 = (float)fVar5;
    fVar5 = (float10)FUN_0057fea0();
    in_stack_00000068 = (float)fVar5;
    fVar5 = (float10)FUN_0057fec0();
    in_stack_0000006c = (float)fVar5;
    fVar5 = (float10)FUN_0057ff00();
    in_stack_00000024 = (undefined4 *)(float)fVar5;
    fVar5 = (float10)FUN_0057ff20();
    in_stack_00000070 = (float)((float10)(float)in_stack_00000024 - fVar5);
    fVar5 = (float10)FUN_0057ff40();
    in_stack_00000074 = (float)fVar5;
    fVar5 = (float10)FUN_0057ff60();
    in_stack_00000078 = (float)fVar5;
    fVar5 = (float10)FUN_0057ff80();
    in_stack_0000007c = (float)fVar5;
    fVar5 = (float10)FUN_0057ffa0();
    in_stack_00000024 = (undefined4 *)(float)fVar5;
    fVar5 = (float10)FUN_0057ffc0();
    in_stack_00000024 = (undefined4 *)(float)((float10)(float)in_stack_00000024 - fVar5);
    fVar5 = (float10)FUN_0057ffe0();
    in_stack_00000080 = (float)((float10)(float)in_stack_00000024 - fVar5);
    fVar5 = (float10)FUN_00580020();
    in_stack_00000084 = (float)fVar5;
    fVar5 = (float10)FUN_005800c0();
    in_stack_00000088 = (float)fVar5;
    fVar5 = (float10)FUN_005800f0();
    in_stack_0000008c = (float)fVar5;
    fVar5 = (float10)FUN_0057fd60();
    in_stack_00000090 = (float)fVar5;
    fVar5 = (float10)FUN_00580730();
    in_stack_00000034 = (float)fVar5;
    fVar5 = (float10)FUN_00580750();
    in_stack_00000044 = (float)fVar5;
  }
  FUN_005d9d50();
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) | 0x40;
  FUN_005d9d30();
  in_stack_00000024 = &stack0x0000004c;
  puVar4 = &DAT_0066b208;
  do {
    uVar2 = FUN_0058dbb0();
    if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(uVar2);
    }
    else {
      FUN_005da180(uVar2,*puVar4);
    }
    puVar4 = puVar4 + 4;
    in_stack_00000024 = in_stack_00000024 + 1;
  } while (puVar4 < &DAT_0066b328);
  FUN_005d9d30();
  FUN_005d9d50();
  uVar2 = FUN_0058dbb0();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(uVar2);
  }
  else {
    FUN_005da180(uVar2,0x8b);
  }
  FUN_005d9d30();
  uVar2 = FUN_0058dbb0();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(uVar2);
  }
  else {
    FUN_005da180(uVar2,0x1b5);
  }
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) & 0xffffffbf;
  FUN_00509230();
  in_stack_00000024 = (undefined4 *)0x12f;
  in_stack_00000028 = 0xef;
  in_stack_00000098 = *(undefined4 *)(in_stack_00000094 + 0x1948);
  in_stack_0000009c = 0;
  in_stack_000000a0 = 0;
  in_stack_00000094 = *(undefined4 *)(in_stack_00000094 + 0x1944);
  puVar4 = (undefined4 *)FUN_00436fd0();
  FUN_005cba50(*puVar4,puVar4[1]);
  return;
}


