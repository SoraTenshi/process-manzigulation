#include <cstdio>
#include <cstdlib>
#include <memory>
#include <iomanip>
#include <iostream>

class AbstractTester {
public:
    virtual void print() = 0;
    virtual void another_print() = 0;
};

class Tester : public AbstractTester {
public:
    Tester() = default;
    ~Tester() = default;

    void print() override {
        std::cout << "This is a tester" << std::endl;
    }

    void another_print() override {
        std::cout << "This is another tester!" << std::endl;
    }
};

template<typename T>
void printAddress(const std::string& prefix, T* obj, void (T::*ptr)()) {
    uintptr_t vmtAddress = (uintptr_t)*reinterpret_cast<uintptr_t**>(obj);
    uintptr_t functionOffset = *reinterpret_cast<uintptr_t*>(&ptr);
    uintptr_t functionAddress = vmtAddress + functionOffset;

    std::cout << prefix << std::hex << std::setfill('0') << std::setw(16) << functionAddress << std::endl;
}

int main() {
    auto tester = std::make_unique<Tester>();

    while (true) {
        std::cout << "Base Address: 0x" << std::hex << std::setfill('0') << std::setw(16) << reinterpret_cast<uintptr_t**>(tester.get()) << std::endl;
        std::cout << "VTable Address: 0x" << std::hex << std::setfill('0') << std::setw(16) << reinterpret_cast<uintptr_t**>(tester.get())[0] << std::endl;
        std::cout << "Method[0] Address: 0x" << std::hex << std::setfill('0') << std::setw(16) << reinterpret_cast<uintptr_t***>(tester.get())[0][0] << std::endl;
        std::cout << "Method[1] Address: 0x" << std::hex << std::setfill('0') << std::setw(16) << reinterpret_cast<uintptr_t***>(tester.get())[0][1] << std::endl;

        tester->print();
        tester->another_print();
        getchar();
    }

    return EXIT_SUCCESS;
}
