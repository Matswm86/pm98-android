// FUN_005a50c0  entry=005a50c0  size=872 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

uint __fastcall FUN_005a50c0(int param_1)

{
  int iVar1;
  bool bVar2;
  uint uVar3;
  int *piVar4;
  undefined4 uVar5;
  int iVar6;
  undefined4 *puVar7;
  int iVar8;
  
  iVar1 = *(int *)(param_1 + 0x40);
  uVar3 = *(int *)(param_1 + 0x30) + 1U & 3;
  *(uint *)(param_1 + 0x30) = uVar3;
  if (iVar1 != 0x1d) {
    if (*(int *)(param_1 + 0x48) != 0) {
      *(int *)(param_1 + 0x48) = *(int *)(param_1 + 0x48) + -1;
      return uVar3;
    }
    if (uVar3 != 0) {
      return uVar3;
    }
    if (*(int *)(param_1 + 0x68) < 0) {
      if ((iVar1 < 0) || (3 < iVar1)) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if (bVar2) {
        iVar8 = (&DAT_00664fb8)[iVar1];
        iVar1 = *(int *)(param_1 + 0x2c) + -1 + iVar8;
        *(int *)(param_1 + 0x2c) = iVar1 % iVar8;
        return iVar1 / iVar8;
      }
    }
    iVar8 = *(int *)(param_1 + 0x2c) + 1;
    uVar3 = iVar8 / (int)(&DAT_00664fb8)[iVar1];
    iVar8 = iVar8 % (int)(&DAT_00664fb8)[iVar1];
    *(int *)(param_1 + 0x2c) = iVar8;
    if (iVar8 != 0) {
      return uVar3;
    }
    if (iVar1 != 0x15) {
      uVar3 = *(uint *)(&DAT_00665208 + iVar1 * 4);
      *(uint *)(param_1 + 0x40) = uVar3;
      return uVar3;
    }
    *(short *)(param_1 + 0x34) = *(short *)(param_1 + 0x34) + -0x4000;
    *(undefined4 *)(param_1 + 0x40) = 10;
    *(undefined4 *)(param_1 + 0x2c) = 5;
    return uVar3;
  }
  piVar4 = &DAT_006653d0;
  if (*(int *)(param_1 + 700) != 0) {
    piVar4 = (int *)(s_HIJKLMNOXYZ_____PQRSTUVW_006653a8 + 0x18);
  }
  iVar1 = *(int *)(param_1 + 0x48);
  if (iVar1 == -0x78) {
    FUN_005a5430(*piVar4);
    uVar3 = FUN_005aac30();
    *(undefined4 *)(param_1 + 0x48) = 0;
    return uVar3;
  }
  if (iVar1 != 0) {
    if (iVar1 == -0x50) {
      iVar1 = *piVar4;
      _DAT_00665154 = (&DAT_006650e0)[iVar1];
      _DAT_0066502c = (&DAT_00664fb8)[iVar1];
      _DAT_0067455c = (&DAT_006744e8)[iVar1];
    }
    else if (iVar1 == -100) {
      iVar1 = piVar4[2];
      _DAT_00665154 = (&DAT_006650e0)[iVar1];
      _DAT_0066502c = (&DAT_00664fb8)[iVar1];
      _DAT_0067455c = (&DAT_006744e8)[iVar1];
      piVar4 = (int *)FUN_005ee0f0(0x30000,CONCAT22((short)((uint)_DAT_00665154 >> 0x10),
                                                    *(undefined2 *)(param_1 + 0x34)));
      iVar1 = *piVar4;
      iVar8 = piVar4[1];
      iVar6 = piVar4[2] + *(int *)(param_1 + 0xc);
      *(undefined4 *)(param_1 + 0x80) = 1;
      *(undefined4 *)(param_1 + 0x84) = 0x28;
      *(int *)(param_1 + 0x94) = *(int *)(param_1 + 4) + iVar1;
      *(int *)(param_1 + 0x98) = iVar8 + *(int *)(param_1 + 8);
      *(int *)(param_1 + 0x9c) = iVar6;
      *(undefined2 *)(param_1 + 0x66) = *(undefined2 *)(param_1 + 0x34);
      puVar7 = (undefined4 *)
               FUN_005ee0f0(0x1333,CONCAT22((short)((uint)iVar6 >> 0x10),
                                            *(undefined2 *)(param_1 + 0x34)));
      *(undefined4 *)(param_1 + 0x20) = *puVar7;
      *(undefined4 *)(param_1 + 0x24) = puVar7[1];
      *(undefined4 *)(param_1 + 0x28) = puVar7[2];
    }
    goto LAB_005a533e;
  }
  iVar1 = piVar4[1];
  _DAT_00665154 = (&DAT_006650e0)[iVar1];
  _DAT_0066502c = (&DAT_00664fb8)[iVar1];
  _DAT_0067455c = (&DAT_006744e8)[iVar1];
  piVar4 = (int *)FUN_005ee0f0(0x30000,CONCAT22((short)((uint)(iVar1 * 4) >> 0x10),
                                                *(undefined2 *)(param_1 + 0x34)));
  iVar1 = *piVar4;
  iVar8 = piVar4[1];
  iVar6 = piVar4[2];
  *(undefined4 *)(param_1 + 0x80) = 1;
  *(int *)(param_1 + 0x94) = *(int *)(param_1 + 4) - iVar1;
  *(undefined2 *)(param_1 + 0x66) = *(undefined2 *)(param_1 + 0x34);
  iVar1 = *(int *)(param_1 + 0x18c);
  *(int *)(param_1 + 0x98) = *(int *)(param_1 + 8) - iVar8;
  *(undefined4 *)(param_1 + 0x84) = 0x50;
  *(int *)(param_1 + 0x9c) = *(int *)(param_1 + 0xc) - iVar6;
  iVar8 = *(int *)(iVar1 + 0x448);
  if (iVar8 == 4) {
    uVar5 = 0xd;
LAB_005a524c:
    FUN_00594470(uVar5,param_1,0);
  }
  else {
    if (iVar8 == 5) {
      if ((*(int *)(iVar1 + 0x19cc) != 0) && (*(char *)(iVar1 + 0x180a) != '\0')) {
        FUN_00590f00();
      }
      uVar5 = 2;
      goto LAB_005a524c;
    }
    if (iVar8 == 7) {
      uVar5 = FUN_005ec240();
      if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
        FUN_00606220();
      }
      FUN_005ec230(uVar5);
      if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180a) != '\0') {
        FUN_00590f00();
      }
      uVar5 = 10;
      goto LAB_005a524c;
    }
  }
  FUN_005942e0(1);
LAB_005a533e:
  uVar3 = *(int *)(param_1 + 0x48) - 1;
  *(uint *)(param_1 + 0x48) = uVar3;
  if (*(int *)(param_1 + 0x30) == 0) {
    if ((int)uVar3 < -100) {
      iVar8 = *(int *)(param_1 + 0x2c) + 1;
      iVar1 = (&DAT_00664fb8)[*(int *)(param_1 + 0x40)];
      *(int *)(param_1 + 0x2c) = iVar8 % iVar1;
      return iVar8 / iVar1;
    }
    if ((int)uVar3 < 0) {
      iVar8 = (&DAT_00664fb8)[*(int *)(param_1 + 0x40)];
      iVar1 = *(int *)(param_1 + 0x2c) + -1 + iVar8;
      *(int *)(param_1 + 0x2c) = iVar1 % iVar8;
      return iVar1 / iVar8;
    }
  }
  return uVar3;
}


