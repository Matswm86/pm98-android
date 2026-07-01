// FUN_005d34a0  entry=005d34a0  size=295 bytes

undefined4 __thiscall
FUN_005d34a0(int *param_1,undefined4 param_2,undefined1 param_3,undefined1 param_4,byte *param_5)

{
  byte bVar1;
  undefined4 uVar2;
  undefined4 *puVar3;
  undefined1 uVar4;
  undefined4 in_EAX;
  int iVar5;
  uint3 uVar7;
  int iVar6;
  undefined4 *puVar8;
  undefined3 uVar9;
  uint *puVar10;
  uint *puVar11;
  int iVar12;
  int iVar13;
  char local_5;
  
  if (*param_1 == 0) {
    in_EAX = FUN_005cb2b0();
    local_5 = '\0';
    if ((char)in_EAX == '\0') goto LAB_005d34c1;
  }
  local_5 = '\x01';
LAB_005d34c1:
  iVar6 = CONCAT31((int3)((uint)in_EAX >> 8),local_5);
  if (local_5 != '\0') {
    iVar12 = param_1[6];
    iVar5 = param_1[7] >> 2;
    puVar8 = (undefined4 *)*param_1;
    iVar6 = iVar5;
    if ((iVar5 != 0) && (iVar12 != 0)) {
      puVar10 = (uint *)(CONCAT22((short)((uint)param_2 >> 0x10),CONCAT11(param_4,param_3)) + -4);
      iVar13 = iVar5;
LAB_005d351d:
      do {
        uVar2 = *puVar8;
        uVar9 = (undefined3)((uint)param_5 >> 8);
        bVar1 = *(byte *)CONCAT31(uVar9,(char)((uint)uVar2 >> 8));
        uVar4 = (undefined1)((uint)uVar2 >> 0x18);
        param_5 = (byte *)CONCAT31(uVar9,uVar4);
        uVar7 = (uint3)(CONCAT22((ushort)bVar1 |
                                 (ushort)(((uint)CONCAT11(bVar1,*(undefined1 *)
                                                                 CONCAT31(uVar9,(char)uVar2)) <<
                                          0x18) >> 0x10),
                                 CONCAT11(*(undefined1 *)CONCAT31(uVar9,(char)((uint)uVar2 >> 0x10))
                                          ,uVar4)) >> 8);
        puVar10[1] = (uint)(uVar7 >> 0x10) | uVar7 & 0xff00 | (uVar7 & 0xff) << 0x10 |
                     (uint)*param_5 << 0x18;
        puVar3 = puVar8 + 1;
        puVar11 = puVar10 + 1;
        if (iVar13 != 1) {
          uVar2 = puVar8[1];
          bVar1 = *(byte *)CONCAT31(uVar9,(char)((uint)uVar2 >> 8));
          uVar4 = (undefined1)((uint)uVar2 >> 0x18);
          param_5 = (byte *)CONCAT31(uVar9,uVar4);
          uVar7 = (uint3)(CONCAT22((ushort)bVar1 |
                                   (ushort)(((uint)CONCAT11(bVar1,*(undefined1 *)
                                                                   CONCAT31(uVar9,(char)uVar2)) <<
                                            0x18) >> 0x10),
                                   CONCAT11(*(undefined1 *)
                                             CONCAT31(uVar9,(char)((uint)uVar2 >> 0x10)),uVar4)) >>
                         8);
          puVar10[2] = (uint)(uVar7 >> 0x10) | uVar7 & 0xff00 | (uVar7 & 0xff) << 0x10 |
                       (uint)*param_5 << 0x18;
          puVar3 = puVar8 + 2;
          puVar11 = puVar10 + 2;
          if (iVar13 != 2) {
            uVar2 = puVar8[2];
            bVar1 = *(byte *)CONCAT31(uVar9,(char)((uint)uVar2 >> 8));
            uVar4 = (undefined1)((uint)uVar2 >> 0x18);
            param_5 = (byte *)CONCAT31(uVar9,uVar4);
            uVar7 = (uint3)(CONCAT22((ushort)bVar1 |
                                     (ushort)(((uint)CONCAT11(bVar1,*(undefined1 *)
                                                                     CONCAT31(uVar9,(char)uVar2)) <<
                                              0x18) >> 0x10),
                                     CONCAT11(*(undefined1 *)
                                               CONCAT31(uVar9,(char)((uint)uVar2 >> 0x10)),uVar4))
                           >> 8);
            puVar10[3] = (uint)(uVar7 >> 0x10) | uVar7 & 0xff00 | (uVar7 & 0xff) << 0x10 |
                         (uint)*param_5 << 0x18;
            puVar3 = puVar8 + 3;
            puVar11 = puVar10 + 3;
            if (iVar13 != 3) {
              uVar2 = puVar8[3];
              bVar1 = *(byte *)CONCAT31(uVar9,(char)((uint)uVar2 >> 8));
              uVar4 = (undefined1)((uint)uVar2 >> 0x18);
              param_5 = (byte *)CONCAT31(uVar9,uVar4);
              puVar10 = puVar10 + 4;
              uVar7 = (uint3)(CONCAT22((ushort)bVar1 |
                                       (ushort)(((uint)CONCAT11(bVar1,*(undefined1 *)
                                                                       CONCAT31(uVar9,(char)uVar2))
                                                << 0x18) >> 0x10),
                                       CONCAT11(*(undefined1 *)
                                                 CONCAT31(uVar9,(char)((uint)uVar2 >> 0x10)),uVar4))
                             >> 8);
              puVar8 = puVar8 + 4;
              *puVar10 = (uint)(uVar7 >> 0x10) | uVar7 & 0xff00 | (uVar7 & 0xff) << 0x10 |
                         (uint)*param_5 << 0x18;
              iVar13 = iVar13 + -4;
              puVar3 = puVar8;
              puVar11 = puVar10;
              if (iVar13 != 0) goto LAB_005d351d;
            }
          }
        }
        puVar8 = puVar3;
        iVar6 = 0;
        puVar11[1] = 0;
        puVar11[2] = 0;
        puVar10 = puVar11 + (0x40 - iVar5);
        iVar12 = iVar12 + -1;
        iVar13 = iVar5;
      } while (iVar12 != 0);
    }
  }
  return CONCAT31((int3)((uint)iVar6 >> 8),local_5);
}


