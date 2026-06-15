// FUN_00470670  entry=00470670  size=67 bytes

int FUN_00470670(int param_1)

{
  undefined4 local_204;
  CHAR local_200 [512];
  
  if (param_1 == 0) {
    local_204 = 0xffff0002;
    lstrcpyA(local_200,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0063ac98);
  }
  return param_1;
}


