// FUN_005841e0  entry=005841e0  size=290 bytes

void __thiscall
FUN_005841e0(int param_1,uint *param_2,uint *param_3,uint *param_4,uint *param_5,uint *param_6)

{
  byte bVar1;
  byte bVar2;
  byte bVar3;
  byte bVar4;
  char cVar5;
  int iVar6;
  uint uVar7;
  
  FUN_00582db0();
  bVar1 = *(byte *)(param_1 + 0x9c);
  *param_2 = (uint)bVar1;
  bVar2 = *(byte *)(param_1 + 0x9d);
  *param_3 = (uint)bVar2;
  bVar3 = *(byte *)(param_1 + 0x9e);
  *param_4 = (uint)bVar3;
  bVar4 = *(byte *)(param_1 + 0x9f);
  *param_5 = (uint)bVar4;
  uVar7 = (int)((uint)bVar4 + (uint)bVar3 + (uint)bVar2 + (uint)bVar1) >> 2;
  if (*(byte *)(param_1 + 0x19) < 0xc) {
    FUN_00585ee0(*(undefined2 *)(param_1 + 0x14));
    iVar6 = FUN_005793d0();
    if ((iVar6 != 0) && (*(int *)(iVar6 + 0x5c) != 0xffff)) {
      if (*(byte *)(param_1 + 0x19) == 1) {
        if (*(char *)(param_1 + 0x1c) != '\0') {
          *param_6 = uVar7 / 2;
          return;
        }
      }
      else {
        cVar5 = *(char *)(param_1 + 0x1c);
        if (cVar5 == '\0') {
          *param_6 = uVar7 / 2;
          return;
        }
        iVar6 = (*(byte *)(param_1 + 0x19) + 2) * 0x20 + iVar6;
        if (cVar5 == '\x01') {
          if (*(int *)(iVar6 + 0x10) < 0x6b) goto LAB_005842f6;
        }
        else if (cVar5 == '\x02') {
          if ((*(int *)(iVar6 + 0x10) < 0xb6) && (0x59 < *(int *)(iVar6 + 0x10))) goto LAB_005842f6;
        }
        else if (0xd3 < *(int *)(iVar6 + 0x18)) goto LAB_005842f6;
        uVar7 = (int)(uVar7 * 3) >> 2;
      }
    }
  }
LAB_005842f6:
  *param_6 = uVar7;
  return;
}


