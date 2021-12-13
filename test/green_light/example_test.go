package green_light

import (
	"testing"
)

func anotherFunction() {}
func TestExample(t *testing.T) {
	result := MyTestItem()
	if result != 1234 {
		t.Errorf("This is actually expected")
	}
}

func TestExample2(t *testing.T) {
	result := MyTestItem()
	if result != 5 {
		t.Errorf("Got some other stuff")
	}
}

func TestAgain(t *testing.T) {
	panic("AHHHHHHHHHHHHHHHHHHHHH")
}
