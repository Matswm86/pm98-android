// FUN_00508be4  entry=00508be4  size=1556 bytes

void __fastcall FUN_00508be4(undefined4 param_1,undefined4 *param_2)

{
  undefined4 in_EAX;
  undefined4 uVar1;
  int iVar2;
  int unaff_EBX;
  int unaff_ESI;
  uint uVar3;
  undefined4 *puVar4;
  float10 fVar5;
  float10 fVar6;
  float10 fVar7;
  undefined4 in_stack_00000030;
  undefined4 in_stack_00000034;
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
  float in_stack_00000094;
  int in_stack_00000098;
  undefined4 in_stack_0000009c;
  undefined4 in_stack_000000a0;
  undefined4 in_stack_000000a4;
  
  *param_2 = in_EAX;
  param_2[1] = param_1;
  param_2[2] = in_stack_00000030;
  param_2[3] = in_stack_00000034;
  FUN_005da180(s_LOANS_AND_INTEREST_00659a78);
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) & 0xffffffdf;
  if (*(int *)(in_stack_00000098 + 0x1928) == unaff_EBX) {
    puVar4 = &stack0x00000050;
    for (iVar2 = 0x12; iVar2 != 0; iVar2 = iVar2 + -1) {
      *puVar4 = 0;
      puVar4 = puVar4 + 1;
    }
    uVar3 = 0;
    do {
      fVar5 = (float10)FUN_005804d0();
      in_stack_00000050 = (float)(fVar5 + (float10)in_stack_00000050);
      fVar5 = (float10)FUN_005806a0();
      fVar6 = (float10)FUN_00580660();
      fVar7 = (float10)FUN_00580540();
      in_stack_00000054 =
           (float)(fVar7 + (float10)(float)(fVar6 + (float10)(float)fVar5) +
                  (float10)in_stack_00000054);
      fVar5 = (float10)FUN_00580610();
      in_stack_00000058 = (float)(fVar5 + (float10)in_stack_00000058);
      fVar5 = (float10)FUN_005806e0();
      in_stack_0000005c = (float)(fVar5 + (float10)in_stack_0000005c);
      fVar5 = (float10)FUN_0057fee0();
      in_stack_00000060 = (float)(fVar5 + (float10)in_stack_00000060);
      fVar5 = (float10)FUN_00580000();
      in_stack_00000064 = (float)(fVar5 + (float10)in_stack_00000064);
      fVar5 = (float10)FUN_0057fe00();
      in_stack_00000068 = (float)(fVar5 + (float10)in_stack_00000068);
      fVar5 = (float10)FUN_0057fea0();
      in_stack_0000006c = (float)(fVar5 + (float10)in_stack_0000006c);
      fVar5 = (float10)FUN_0057fec0();
      in_stack_00000070 = (float)(fVar5 + (float10)in_stack_00000070);
      fVar5 = (float10)FUN_0057ff00();
      fVar6 = (float10)FUN_0057ff20();
      in_stack_00000074 = (float)(((float10)(float)fVar5 - fVar6) + (float10)in_stack_00000074);
      fVar5 = (float10)FUN_0057ff40();
      in_stack_00000078 = (float)(fVar5 + (float10)in_stack_00000078);
      fVar5 = (float10)FUN_0057ff60();
      in_stack_0000007c = (float)(fVar5 + (float10)in_stack_0000007c);
      fVar5 = (float10)FUN_0057ff80();
      in_stack_00000080 = (float)(fVar5 + (float10)in_stack_00000080);
      fVar5 = (float10)FUN_0057ffa0();
      fVar6 = (float10)FUN_0057ffc0();
      fVar7 = (float10)FUN_0057ffe0();
      in_stack_00000084 =
           (float)(((float10)(float)((float10)(float)fVar5 - fVar6) - fVar7) +
                  (float10)in_stack_00000084);
      fVar5 = (float10)FUN_00580020();
      in_stack_00000088 = (float)(fVar5 + (float10)in_stack_00000088);
      fVar5 = (float10)FUN_005800c0();
      in_stack_0000008c = (float)(fVar5 + (float10)in_stack_0000008c);
      fVar5 = (float10)FUN_005800f0();
      in_stack_00000090 = (float)(fVar5 + (float10)in_stack_00000090);
      fVar5 = (float10)FUN_0057fd60();
      in_stack_00000094 = (float)(fVar5 + (float10)in_stack_00000094);
      FUN_00580730();
      FUN_00580750();
      uVar3 = uVar3 + 1;
    } while (uVar3 < 0x34);
  }
  else {
    fVar5 = (float10)FUN_005804d0();
    in_stack_00000050 = (float)fVar5;
    fVar5 = (float10)FUN_005806a0();
    fVar6 = (float10)FUN_00580660();
    fVar7 = (float10)FUN_00580540();
    in_stack_00000054 = (float)(fVar7 + (float10)(float)(fVar6 + (float10)(float)fVar5));
    fVar5 = (float10)FUN_00580610();
    in_stack_00000058 = (float)fVar5;
    fVar5 = (float10)FUN_005806e0();
    in_stack_0000005c = (float)fVar5;
    fVar5 = (float10)FUN_0057fee0();
    in_stack_00000060 = (float)fVar5;
    fVar5 = (float10)FUN_00580000();
    in_stack_00000064 = (float)fVar5;
    fVar5 = (float10)FUN_0057fe00();
    in_stack_00000068 = (float)fVar5;
    fVar5 = (float10)FUN_0057fea0();
    in_stack_0000006c = (float)fVar5;
    fVar5 = (float10)FUN_0057fec0();
    in_stack_00000070 = (float)fVar5;
    fVar5 = (float10)FUN_0057ff00();
    fVar6 = (float10)FUN_0057ff20();
    in_stack_00000074 = (float)((float10)(float)fVar5 - fVar6);
    fVar5 = (float10)FUN_0057ff40();
    in_stack_00000078 = (float)fVar5;
    fVar5 = (float10)FUN_0057ff60();
    in_stack_0000007c = (float)fVar5;
    fVar5 = (float10)FUN_0057ff80();
    in_stack_00000080 = (float)fVar5;
    fVar5 = (float10)FUN_0057ffa0();
    fVar6 = (float10)FUN_0057ffc0();
    fVar7 = (float10)FUN_0057ffe0();
    in_stack_00000084 = (float)((float10)(float)((float10)(float)fVar5 - fVar6) - fVar7);
    fVar5 = (float10)FUN_00580020();
    in_stack_00000088 = (float)fVar5;
    fVar5 = (float10)FUN_005800c0();
    in_stack_0000008c = (float)fVar5;
    fVar5 = (float10)FUN_005800f0();
    in_stack_00000090 = (float)fVar5;
    fVar5 = (float10)FUN_0057fd60();
    in_stack_00000094 = (float)fVar5;
    FUN_00580730();
    FUN_00580750();
  }
  FUN_005d9d50();
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) | 0x40;
  FUN_005d9d30();
  puVar4 = &DAT_0066b208;
  do {
    uVar1 = FUN_0058dbb0();
    if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80();
    }
    else {
      FUN_005da180(uVar1);
    }
    puVar4 = puVar4 + 4;
  } while (puVar4 < &DAT_0066b328);
  FUN_005d9d30();
  FUN_005d9d50();
  uVar1 = FUN_0058dbb0();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(uVar1);
  }
  FUN_005d9d30();
  uVar1 = FUN_0058dbb0();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(uVar1);
  }
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) & 0xffffffbf;
  FUN_00509230();
  in_stack_0000009c = *(undefined4 *)(in_stack_00000098 + 0x1948);
  in_stack_000000a0 = 0;
  in_stack_000000a4 = 0;
  in_stack_00000098 = *(undefined4 *)(in_stack_00000098 + 0x1944);
  puVar4 = (undefined4 *)FUN_00436fd0();
  FUN_005cba50(*puVar4);
  return;
}


