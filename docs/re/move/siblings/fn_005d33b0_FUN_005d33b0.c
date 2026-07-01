// FUN_005d33b0  entry=005d33b0  size=232 bytes

undefined4 __thiscall
FUN_005d33b0(int *param_1,undefined4 param_2,undefined1 param_3,undefined1 param_4)

{
  int *piVar1;
  undefined4 in_EAX;
  int iVar2;
  int iVar3;
  int *piVar4;
  int *piVar5;
  int iVar6;
  int iVar7;
  char local_5;
  
  if (*param_1 == 0) {
    in_EAX = FUN_005cb2b0();
    local_5 = '\0';
    if ((char)in_EAX == '\0') goto LAB_005d33d1;
  }
  local_5 = '\x01';
LAB_005d33d1:
  iVar3 = CONCAT31((int3)((uint)in_EAX >> 8),local_5);
  if (local_5 != '\0') {
    iVar6 = param_1[6];
    iVar2 = param_1[7] >> 2;
    param_1 = (int *)*param_1;
    iVar3 = iVar2;
    if ((iVar2 != 0) && (iVar6 != 0)) {
      piVar4 = (int *)CONCAT22((short)((uint)param_2 >> 0x10),CONCAT11(param_4,param_3));
      iVar7 = iVar2;
LAB_005d3428:
      do {
        iVar3 = *param_1;
        *piVar4 = iVar3;
        piVar1 = param_1 + 1;
        piVar5 = piVar4 + 1;
        if (iVar7 != 1) {
          iVar3 = param_1[1];
          piVar4[1] = iVar3;
          piVar1 = param_1 + 2;
          piVar5 = piVar4 + 2;
          if (iVar7 != 2) {
            iVar3 = param_1[2];
            piVar4[2] = iVar3;
            piVar1 = param_1 + 3;
            piVar5 = piVar4 + 3;
            if (iVar7 != 3) {
              iVar3 = param_1[3];
              piVar4[3] = iVar3;
              piVar1 = param_1 + 4;
              piVar5 = piVar4 + 4;
              if (iVar7 != 4) {
                iVar3 = param_1[4];
                piVar4[4] = iVar3;
                piVar1 = param_1 + 5;
                piVar5 = piVar4 + 5;
                if (iVar7 != 5) {
                  iVar3 = param_1[5];
                  piVar4[5] = iVar3;
                  piVar1 = param_1 + 6;
                  piVar5 = piVar4 + 6;
                  if (iVar7 != 6) {
                    iVar3 = param_1[6];
                    piVar4[6] = iVar3;
                    piVar1 = param_1 + 7;
                    piVar5 = piVar4 + 7;
                    if (iVar7 != 7) {
                      iVar3 = param_1[7];
                      param_1 = param_1 + 8;
                      piVar4[7] = iVar3;
                      piVar4 = piVar4 + 8;
                      iVar7 = iVar7 + -8;
                      if (iVar7 != 0) goto LAB_005d3428;
                      *piVar4 = 0;
                      piVar1 = param_1;
                      piVar5 = piVar4;
                    }
                  }
                }
              }
            }
          }
        }
        param_1 = piVar1;
        piVar4 = piVar5 + (0x40 - iVar2);
        iVar6 = iVar6 + -1;
        iVar7 = iVar2;
      } while (iVar6 != 0);
    }
  }
  return CONCAT31((int3)((uint)iVar3 >> 8),local_5);
}


