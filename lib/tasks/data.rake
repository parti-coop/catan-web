namespace :data do
  desc "seed group"
  task 'seed:group' => :environment do
    user = User.find_by(nickname: 'parti')
    Group.transaction do
      seed_group(user, 'indie', [],
        title: '일반',
        site_title: '일반',
        head_title: '일반')

      seed_group(user, 'gwangju', [],
        title: '광주',
        site_title: '민주주의 플랫폼 - 광주빠띠',
        head_title: '광주')

      seed_group(user, 'do', [],
        title: '나는 알아야겠당',
        site_title: 'GMO 완전표시제법 - 나는 알아야겠당',
        head_title: '나알당')

      seed_group(user, 'change', [],
        title: '바꿈',
        site_title: '세상을 바꾸는 꿈 - 바꿈',
        head_title: '바꿈')

      seed_group(user, 'toktok', [],
        title: '국회톡톡',
        site_title: '내게 필요한 법, 국회에 직접 제안해서 만들어봐요 - 국회톡톡',
        head_title: '국회톡톡')

      seed_group(user, 'innovators', [],
        title: 'N명의 사회혁신가',
        site_title: '함께 새로운 세상을 만들자 - N명의 사회혁신가',
        head_title: 'N명혁신가',
        site_description: '사회혁신가는 일상에서 대안과 해결책을 고민하고 제안하며, 구체적인 그림과 방법을 연구하고, 각자의 현장에서 실천하고자 하는 사람들입니다.',
        site_keywords: '함께, 새로운세상을, 만들자, 사회혁신가, 소셜벤처, 박근혜게이트, 정치, 시국선언')

      seed_group(user, 'slowalk', [],
        title: '슬로워크',
        site_title: '슬로워크',
        head_title: '슬로워크',
        private: true)

      seed_group(user, 'westay1', [],
        title: '함께살아보장',
        site_title: '함께살아보장 - 별내 위스테이 공동체 사회적협동조합',
        head_title: '함께살아보장',
        site_description: '별내지구에 조성될 위스테이 아파트 입주자(조합원)의 온라인 커뮤니케이션 채널입니다. 사회적협동조합의 정관과 사업계획에서 다양한 공동체 소모임까지 조합원들과 함께 만들어 갑니다.',
        private: true)

      seed_group(user, 'wouldyou', [],
        title: '우주당',
        site_title: '우리가 주인이당 - 우주당',
        head_title: '우주당',
        site_description: '직접 민주주의 프로젝트 정당 우주당입니다. 우리가 주인이 되어 우리의 이야기로 정치하는, 새롭고 즐거운 시도들을 함께 해요!',
        site_keywords: '정치, 정당, 우주당, 직접민주주의, 해적당, wouldyouparty, 빠띠, 민주주의')

      seed_group(user, Group::SLUG_OF_UNION, [],
        title: '빠띠유니온',
        site_title: '민주주의 벤처 - 빠띠유니온',
        site_description: '일상을 더 민주적으로! 민주주의 벤처 빠띠는 우리 사회 곳곳에 민주주의를 확산시키기 위해 노력합니다.',
        head_title: '빠띠유니온',
        private: false)

      seed_group(user, 'meetshare', ['berry', '갱'],
        title: '미트쉐어',
        site_title: '작지만 멋진 일 - 미트쉐어',
        head_title: '미트쉐어',
        private: false)

      seed_group(user, 'youthchange', ['천은선'],
        title: '시작된변화',
        site_title: '청소년마을프로젝트 - 시작된변화',
        head_title: '시작된변화',
        site_description: "'마을'을 위해, '사람'을 위해, 청소년이 만들어가는 '변화'. 대책 없는 상상력과 무시무시한 실행력으로 마을의 변화를 만드는 청소년들의 이야기가 흘러넘치는 곳, 시작된변화 빠띠입니다.",
        private: false)

      seed_group(user, 'adaptiveleadership', ['gingertproject'],
        title: '어댑티브 리더십',
        site_title: '함께 읽는 어댑티브 리더십',
        head_title: '변화리더십',
        site_description: "조직의 문제와 나의 문제를 고민하는 사람들이 모여, 이전에는 시도되지 않은 실험을 해나가면서 해결책을 도출해 나가는 변화 리더십에 대한 고민과 생각을 나눕니다.",
        private: false)

      seed_group(user, 'youthpolicynet', ['odong'],
        title: '전국청년정책네트워크',
        site_title: '다음세대를 위한 새로운 시작 - 전국청년정책네트워크',
        head_title: '전청넷',
        site_description: "<전국청년정책네트워크>는 이행기 청년의 불평등 문제를 지역 간 협력과 제도 개선을 통해 해결하는 자발적 시민 네트워크입니다.",
        private: false)

      seed_group(user, 'eduhope', ['갱'],
        title: '전교조',
        site_title: '교육과 세상을 바꾸는 전교조',
        head_title: '전교조',
        site_description: "교육의 자주성, 전문성 확립과 교육민주화 실현을 위한 전국의 유치원, 초등학교, 중·고등학교 교사들의 자주적 노동조합입니다.",
        private: false)

      Issue.where(group_slug: 'duckup').update_all(group_slug: 'indie')
      Group.find_by(slug: 'duckup').try(:destroy!)
      Group.find_by(slug: 'zakdang').try(:destroy!)

    end
  end

  def seed_group(admin, group_slug, organizer_nicknames, options)
    organizer_users = User.where(nickname: organizer_nicknames)
    group = Group.find_or_initialize_by slug: group_slug
    group.assign_attributes({ private: false }.merge(options))
    group.user = admin
    organizer_users.each do |user|
      organizer_member = group.members.find_or_initialize_by(user: user)
      organizer_member.is_organizer = true
    end
    group.members.all.select { |organizer| !organizer_users.include?(organizer.user) }.map { |member| member.is_organizer = false }
    group.save!

    group
  end
end
