// FUN_005902b0  entry=005902b0  size=1854 bytes

void __thiscall FUN_005902b0(int param_1,int param_2)

{
  undefined4 uVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  bool bVar7;
  uint uStack_cc;
  uint uStack_c8;
  uint uStack_c4;
  uint uStack_c0;
  int iStack_bc;
  int iStack_b8;
  uint uStack_ac;
  int iStack_a8;
  int iStack_a4;
  int iStack_a0;
  int iStack_9c;
  uint uStack_98;
  int iStack_90;
  undefined4 uStack_8c;
  int iStack_88;
  int iStack_84;
  int iStack_7c;
  uint uStack_78;
  int iStack_74;
  int iStack_70;
  undefined4 uStack_6c;
  uint uStack_68;
  int iStack_64;
  int iStack_60;
  undefined4 uStack_5c;
  undefined4 uStack_58;
  undefined4 uStack_54;
  int iStack_50;
  undefined4 uStack_4c;
  undefined4 uStack_48;
  int iStack_44;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  int iStack_2c;
  int iStack_28;
  undefined4 uStack_24;
  undefined1 auStack_20 [32];
  
  if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x5fac) == '\0') {
    if (*(char *)(param_1 + 0x60) != '\0') {
      iVar2 = *(short *)(param_2 + 0xdc) * 0x20;
      uVar6 = *(int *)(param_1 + 0x2c) - ((int)(iVar2 + (iVar2 >> 0x1f & 0xffffU)) >> 0x10);
      uStack_c4 = (uVar6 & 7) * 0x20;
      uStack_c0 = (((int)(uVar6 & 0xf) >> 3) + 4) * 0x20 +
                  (-(uint)(*(char *)(param_1 + 0x1d8) != '\0') & 0xffffffc0) + 0x40;
      uVar6 = uStack_c4 + 0x18;
      uStack_cc = uStack_c4;
      if (uVar6 <= uStack_c4) {
        uStack_cc = uVar6;
      }
      if (uStack_c4 <= uVar6) {
        uStack_c4 = uVar6;
      }
      uVar6 = uStack_c0 + 0x18;
      uStack_c8 = uStack_c0;
      if ((int)uVar6 <= (int)uStack_c0) {
        uStack_c8 = uVar6;
      }
      if ((int)uStack_c0 <= (int)uVar6) {
        uStack_c0 = uVar6;
      }
      uStack_98 = 0xb0;
      iStack_90 = 200;
      uStack_8c = 0x18;
      FUN_005ee5c0(&uStack_ac,param_2 + 0x4c);
      iVar2 = (int)*(short *)(*(int *)(param_1 + 0x1d4) + 0x181e);
      uVar1 = *(undefined4 *)(&DAT_006d31c8 + (iVar2 + 0x4008 >> 4 & 0xfffU) * 4);
      iVar3 = FUN_005edfa0(*(undefined4 *)(&DAT_006d31c8 + (-8 - iVar2 >> 4 & 0xfffU) * 4),
                           *(undefined4 *)(param_1 + 0xc));
      iVar2 = *(int *)(param_1 + 8);
      iStack_2c = FUN_005edfa0(uVar1,*(undefined4 *)(param_1 + 0xc));
      iStack_2c = iStack_2c + *(int *)(param_1 + 4);
      uStack_24 = 0;
      if (0xff < (int)uStack_ac) {
        if ((uStack_ac & 0xffffff00) == 0) {
          iVar5 = -1;
        }
        else {
          iVar5 = -((int)uStack_ac >> 8);
        }
        iVar4 = iStack_a8 / iVar5;
        iStack_7c = iStack_a4 / iVar5;
        iStack_28 = iVar3 + iVar2;
        FUN_00590aa0(uStack_ac,*(int *)(param_2 + 0xf8) * 0x10 + iStack_a8,
                     *(int *)(param_2 + 0xfc) * 0x10 + iStack_a4);
        if ((uStack_68 & 0xffffff00) == 0) {
          iVar2 = -1;
        }
        else {
          iVar2 = -((int)uStack_68 >> 8);
        }
        FUN_00436fb0(iStack_64 / iVar2,iStack_60 / iVar2);
        iVar2 = iStack_7c;
        FUN_00436fb0(iStack_88 - iVar4,iStack_84 - iStack_7c);
        iVar3 = FUN_005edfa0(iStack_bc,0xffffdc29);
        if ((int)(iVar3 + (iVar3 >> 0x1f & 7U)) >> 3 < 1) {
          iVar2 = 1;
        }
        else {
          FUN_00590aa0(uStack_ac,*(int *)(param_2 + 0xf8) * 0x10 + iStack_a8,
                       *(int *)(param_2 + 0xfc) * 0x10 + iStack_a4);
          if ((uStack_78 & 0xffffff00) == 0) {
            iVar3 = -1;
          }
          else {
            iVar3 = -((int)uStack_78 >> 8);
          }
          FUN_00436fb0(iStack_74 / iVar3,iStack_70 / iVar3);
          FUN_00436fb0(iStack_a0 - iVar4,iStack_9c - iVar2);
          iVar2 = FUN_005edfa0(iVar5,0xffffdc29);
          iVar2 = (int)(iVar2 + (iVar2 >> 0x1f & 7U)) >> 3;
        }
        FUN_00436fb0(*(int *)(param_2 + 0xf0) + iVar4,*(int *)(param_2 + 0xf4) + iStack_7c);
        iStack_88 = -(iVar2 / 2);
        FUN_00436fb0(iStack_a0 + iStack_88,iStack_9c + -iVar2);
        FUN_00436fb0(*(int *)(param_2 + 0xf0) + iVar4,*(int *)(param_2 + 0xf4) + iStack_7c);
        iStack_a0 = (iVar2 + 1) / 2;
        FUN_00436fb0(iStack_bc + iStack_a0,iStack_b8 + -iVar2);
        FUN_00436fb0(*(int *)(param_2 + 0xf0) + iVar4,*(int *)(param_2 + 0xf4) + iStack_7c);
        FUN_00436fb0(iStack_bc + iStack_a0,iStack_b8);
        FUN_00436fb0(*(int *)(param_2 + 0xf0) + iVar4,*(int *)(param_2 + 0xf4) + iStack_7c);
        FUN_00436fb0(iStack_bc + iStack_88,iStack_b8);
        FUN_00404a80(&uStack_5c,0xc,4,FUN_005c8f80);
        iStack_50 = FUN_005edfa0(*(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x1940),0x23d7);
        uStack_5c = 0xffffee15;
        iStack_50 = iStack_50 << 1;
        uStack_58 = 0x23d7;
        uStack_4c = 0x23d7;
        uStack_54 = 0;
        uStack_48 = 0;
        uStack_40 = 0xffffdc29;
        uStack_3c = 0;
        uStack_38 = 0xffffee15;
        uStack_34 = 0xffffdc29;
        uStack_30 = 0;
        if (iVar2 < 4) {
          bVar7 = iVar2 == 1;
          uStack_c4 = 3;
          uStack_c0 = 3;
          if (bVar7) {
            uStack_c4 = 2;
            uStack_c0 = 2;
          }
          uStack_cc = (uint)bVar7;
          uStack_c8 = (uint)bVar7;
          uStack_98 = 0x16;
          iStack_90 = 0x19;
          uStack_8c = 3;
        }
        else if (iVar2 < 7) {
          uStack_98 = 0x2c;
          iStack_90 = 0x32;
          uStack_8c = 6;
          uStack_c8 = (int)(uStack_c8 + ((int)uStack_c8 >> 0x1f & 3U)) >> 2;
          uStack_c0 = (int)(uStack_c0 + ((int)uStack_c0 >> 0x1f & 3U)) >> 2;
          uStack_cc = (uint)(((int)uStack_cc >> 2) * 3) / 2;
          uStack_c4 = uStack_cc + 6;
        }
        else if (iVar2 < 0xd) {
          uStack_98 = 0x58;
          iStack_90 = 100;
          uStack_8c = 0xc;
          uStack_c8 = (int)uStack_c8 / 2;
          uStack_c0 = (int)uStack_c0 / 2;
          uStack_cc = (int)((uStack_cc / 2) * 5) >> 2;
          uStack_c4 = uStack_cc + 0xc;
        }
        iVar2 = *(int *)(param_1 + 0x1d4);
        iStack_44 = iStack_50;
        if (*(char *)(iVar2 + 0x1a1c) != '\0') {
          iStack_88 = CONCAT22((short)((uint)iVar2 >> 0x10),*(short *)(iVar2 + 0x181e) + 0x4000);
          iVar2 = 4;
          do {
            FUN_005ee670(iStack_88);
            iVar2 = iVar2 + -1;
          } while (iVar2 != 0);
          FUN_00590a60(&iStack_2c);
          iStack_70 = iStack_90;
          iStack_74 = 0;
          uStack_78 = uStack_98;
          uStack_6c = uStack_8c;
          FUN_005d8520(&uStack_5c,*(int *)(*(int *)(param_1 + 0x1d4) + 0x1a4c) + 0x20000,&uStack_78,
                       6,0,1);
        }
        FUN_00590c50(auStack_20,*(int *)(*(int *)(param_1 + 0x1d4) + 0x1a4c) + 0x20000,uStack_cc,
                     uStack_c8,uStack_c4,uStack_c0);
      }
    }
    return;
  }
  FUN_00590aa0(*(undefined4 *)(param_1 + 4),*(undefined4 *)(param_1 + 8),
               *(int *)(param_1 + 0xc) + 0x23d7);
  iVar2 = *(int *)(param_1 + 0x1d4);
  *(uint *)(iVar2 + 0x298c) = uStack_ac;
  *(int *)(iVar2 + 0x2990) = iStack_a8;
  *(undefined1 *)(iVar2 + 0x29ac) = 1;
  *(int *)(iVar2 + 0x2994) = iStack_a4;
  iVar2 = *(int *)(param_1 + 0x1d4);
  *(undefined2 *)(iVar2 + 0x2998) = *(undefined2 *)(param_1 + 0x34);
  *(undefined2 *)(iVar2 + 0x299a) = 0;
  *(undefined2 *)(iVar2 + 0x299c) = 0;
  *(undefined1 *)(iVar2 + 0x29ac) = 1;
  FUN_005f3480(0);
  FUN_005f34c0(0,0);
  FUN_005db240(1);
  FUN_005f3700(param_2);
  return;
}


