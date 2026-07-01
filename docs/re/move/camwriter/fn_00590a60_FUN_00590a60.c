// FUN_00590a60  entry=00590a60  size=63 bytes

void __thiscall FUN_00590a60(int param_1,int *param_2)

{
  int *piVar1;
  int iVar2;
  
  iVar2 = 4;
  piVar1 = (int *)(param_1 + 0x2c);
  do {
    piVar1[-2] = piVar1[-2] + *param_2;
    piVar1[-1] = piVar1[-1] + param_2[1];
    iVar2 = iVar2 + -1;
    *piVar1 = *piVar1 + param_2[2];
    piVar1 = piVar1 + -3;
  } while (iVar2 != 0);
  return;
}


