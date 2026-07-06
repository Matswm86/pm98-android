// FUN_0044bb20  entry=0044bb20  size=161 bytes

undefined4 __thiscall FUN_0044bb20(int param_1,char *param_2)

{
  char cVar1;
  char *pcVar2;
  uint uVar3;
  uint uVar4;
  char *pcVar5;
  undefined4 local_204;
  CHAR local_200 [512];
  
  operator_delete(*(void **)(param_1 + 0x4c));
  *(undefined4 *)(param_1 + 0x4c) = 0;
  if (param_2 != (char *)0x0) {
    uVar3 = 0xffffffff;
    pcVar2 = param_2;
    do {
      if (uVar3 == 0) break;
      uVar3 = uVar3 - 1;
      cVar1 = *pcVar2;
      pcVar2 = pcVar2 + 1;
    } while (cVar1 != '\0');
    pcVar2 = operator_new(~uVar3);
    if (pcVar2 == (char *)0x0) {
      local_204 = 0xffff0002;
      lstrcpyA(local_200,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0063ac98);
    }
    *(char **)(param_1 + 0x4c) = pcVar2;
    if (pcVar2 != (char *)0x0) {
      uVar3 = 0xffffffff;
      do {
        pcVar5 = param_2;
        if (uVar3 == 0) break;
        uVar3 = uVar3 - 1;
        pcVar5 = param_2 + 1;
        cVar1 = *param_2;
        param_2 = pcVar5;
      } while (cVar1 != '\0');
      uVar3 = ~uVar3;
      pcVar5 = pcVar5 + -uVar3;
      for (uVar4 = uVar3 >> 2; uVar4 != 0; uVar4 = uVar4 - 1) {
        *(undefined4 *)pcVar2 = *(undefined4 *)pcVar5;
        pcVar5 = pcVar5 + 4;
        pcVar2 = pcVar2 + 4;
      }
      for (uVar3 = uVar3 & 3; uVar3 != 0; uVar3 = uVar3 - 1) {
        *pcVar2 = *pcVar5;
        pcVar5 = pcVar5 + 1;
        pcVar2 = pcVar2 + 1;
      }
    }
  }
  return *(undefined4 *)(param_1 + 0x4c);
}


