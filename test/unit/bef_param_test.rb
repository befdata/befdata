require 'test_helper'

class BefParamTest < Test::Unit::TestCase
  test 'checking param existence should work' do
    p = BefParam.new('access_code:0,f:n')
    assert p.has_param?(:access_code)
    assert p.has_param?('f')
    assert !p.has_param?('bla')
  end

  test 'checking param equality should work' do
    p = BefParam.new('access_code:0,f:n', :radio => :f, :checkbox => :access_code)
    assert p.has_param?(:access_code, '0')
    assert !p.has_param?(:access_code, '1')
    assert p.has_param?(:f, 'n')
    assert !p.has_param?(:f, 'w')

    p1 = BefParam.new('access_code:0|1,f:a|w', :radio => :f, :checkbox => :access_code)
    assert p1.has_param?(:access_code, ['0', '1'])
    assert p1.has_param?(:access_code, '1')
    assert p1.has_param?(:f, ['a', 'w'])
    assert !p1.has_param?(:f, 'a')
  end

  test 'set param should work' do
    p = BefParam.new('access_code:0|1,f:a|w', :radio => :f, :checkbox => :access_code)
    p.set_param({:access_code => '0', :f => 'a'})
    assert_not_equal p[:access_code], '0'
    assert_not_equal p[:f], 'a'

    p.set_param!({:access_code => '0', :f => 'a'})
    assert_equal p[:access_code], '0'
    assert_equal p[:f], 'a'
  end

  test 'toggle_param! should work' do
    p = BefParam.new('access_code:0,f:w', :radio => :f, :checkbox => :access_code)
    p.toggle_param!(:access_code, '0')
    assert !p.has_param?(:access_code)
    p.toggle_param!(:access_code, '1')
    assert p.has_param?(:access_code, '1')
    p.toggle_param!(:access_code, '2')
    assert p.has_param?(:access_code, '1') && p.has_param?(:access_code, '2')

    p.toggle_param!(:f, "w")
    assert !p.has_param?(:f)

    p.toggle_param!(:f, 'a')
    assert p.has_param?(:f, 'a')
    p.toggle_param!(:f, ['a', 'w'])
    assert !p.has_param?(:f, 'a')
    assert p.has_param?(:f, ['a', 'w'])
  end

  test 'dup should work' do
    p = BefParam.new('access_code:0|1,f:w', :radio => :f, :checkbox => :access_code)
    p1 = p.dup
    assert p.has_param?(:access_code, '0') && p.has_param?(:access_code, '1')
    assert p1.has_param?(:access_code, '0') && p1.has_param?(:access_code, '1')

    p.toggle_param!(:access_code, '2')
    assert p.has_param?(:access_code, '0') && p.has_param?(:access_code, '1') && p.has_param?(:access_code, '2')
    assert !p1.has_param?(:access_code, '2')
  end
end