#!/bin/bash


test() {

echo "abc"

return 0
echo "cde"
}



test2() {

test

echo "aaa"

}


test2
