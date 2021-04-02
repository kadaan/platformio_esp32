#include <unity.h>

void test_dummy(void) {
  TEST_ASSERT_TRUE(true);
  TEST_ASSERT_EQUAL(0, 0);
}

void process() {
  UNITY_BEGIN();
  RUN_TEST(test_dummy);
  UNITY_END();
}

int main(int argc, char **argv) {
  process();
  return 0;
}
