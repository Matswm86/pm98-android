// FUN_00574830  entry=00574830  size=30 bytes

void * __thiscall FUN_00574830(void *param_1,byte param_2)

{
  thunk_FUN_00526390();
  if ((param_2 & 1) != 0) {
    operator_delete(param_1);
  }
  return param_1;
}


