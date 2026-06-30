// FUN_00454700  entry=00454700  size=36 bytes

uint __cdecl FUN_00454700(uint param_1,uint *param_2)

{
  uint *puVar1;
  uint uVar2;
  uint uVar3;
  
  uVar3 = 0;
  uVar2 = *param_2;
  while (uVar2 != 0) {
    if ((uVar2 & param_1) != 0) {
      uVar3 = uVar3 | param_2[1];
    }
    puVar1 = param_2 + 2;
    param_2 = param_2 + 2;
    uVar2 = *puVar1;
  }
  return uVar3;
}


